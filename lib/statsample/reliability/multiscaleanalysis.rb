module Statsample
  module Reliability
    # DSL for analysis of multiple scales analysis. 
    # Retrieves reliability analysis for each scale and
    # provides fast accessors to correlations matrix,
    # PCA and Factor Analysis.
    # 
    # == Usage
    #  @x1=[1,1,1,1,2,2,2,2,3,3,3,30].to_vector(:scale)
    #  @x2=[1,1,1,2,2,3,3,3,3,4,4,50].to_vector(:scale)
    #  @x3=[2,2,1,1,1,2,2,2,3,4,5,40].to_vector(:scale)
    #  @x4=[1,2,3,4,4,4,4,3,4,4,5,30].to_vector(:scale)
    #  ds={'x1'=>@x1,'x2'=>@x2,'x3'=>@x3,'x4'=>@x4}.to_dataset
    #  opts={:name=>"Scales", # Name of analysis
    #        :summary_correlation_matrix=>true, # Add correlation matrix
    #        :summary_pca } # Add PCA between scales
    #  msa=Statsample::Reliability::MultiScaleAnalysis.new(opts) do |m|
    #    m.scale :s1, ds.clone(%w{x1 x2})
    #    m.scale :s2, ds.clone(%w{x3 x4}), {:name=>"Scale 2"}
    #  end
    #  # Retrieve summary
    #  puts msa.summary 
    class MultiScaleAnalysis
      include Statsample::Summarizable
      # Hash with scales
      attr_reader :scales
      # Name of analysis
      attr_accessor :name
      # Add a correlation matrix on summary
      attr_accessor :summary_correlation_matrix
      # Add PCA to summary
      attr_accessor :summary_pca
      # Add Principal Axis to summary
      attr_accessor :summary_principal_axis
      # Options for Factor::PCA object
      attr_accessor :pca_options
      # Options for Factor::PrincipalAxis 
      attr_accessor :principal_axis_options
      # Generates a new MultiScaleAnalysis
      # Opts could be any accessor of the class 
      # * :name, 
      # * :summary_correlation_matrix
      # * :summary_pca
      # * :summary_principal_axis
      # * :pca_options
      # * :factor_analysis_options
      #
      # If block given, all methods should be called
      # inside object environment.
      # 
      def initialize(opts=Hash.new, &block)
        @scales=Hash.new
        opts_default={  :name=>_("Multiple Scale analysis"),
                        :summary_correlation_matrix=>false,
                        :summary_pca=>false,
                        :summary_principal_axis=>false,
                        :pca_options=>Hash.new,
                        :principal_axis_options=>Hash.new
        }
        @opts=opts_default.merge(opts)
        @opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }

        if block
          block.arity<1 ? instance_eval(&block) : block.call(self)
        end
      end
      # Add or retrieve a scale to analysis.
      # If second parameters is a dataset, generates a ScaleAnalysis 
      # for <tt>ds</tt>, named <tt>code</tt> with options <tt>opts</tt>.
      # 
      # If second parameters is empty, returns the ScaleAnalysis
      # <tt>code</tt>.
      def scale(code,ds=nil, opts=nil)
        if ds.nil?
          @scales[code]
        else
          opts={:name=>_("Scale %s") % code} if opts.nil?
          @scales[code]=ScaleAnalysis.new(ds, opts)
        end
      end
      # Delete ScaleAnalysis named <tt>code</tt>
      def delete_scale(code)
        @scales.delete code
      end
      # Retrieves a Principal Component Analysis (Factor::PCA)
      # using all scales, using <tt>opts</tt> a options.
      def pca(opts=nil)
        opts||=pca_options        
        Statsample::Factor::PCA.new(correlation_matrix,opts)
      end
      # Retrieves a PrincipalAxis Analysis (Factor::PrincipalAxis)
      # using all scales, using <tt>opts</tt> a options.
      def principal_axis_analysis(opts=nil)
        opts||=principal_axis_options
        Statsample::Factor::PrincipalAxis.new(correlation_matrix,opts)
      end
      # Retrieves a Correlation Matrix between scales.
      # 
      def correlation_matrix
        vectors=Hash.new
        @scales.each_pair do |code,scale|
          vectors[code.to_s]=scale.ds.vector_sum
        end
        Statsample::Bivariate.correlation_matrix(vectors.to_dataset)
      end
      def report_building(b) # :nodoc:
        b.section(:name=>name) do |s|
          s.section(:name=>_("Reliability analysis of scales")) do |s2|
            @scales.each_pair do |k,scale|
              s2.parse_element(scale)
            end
          end
          if summary_correlation_matrix
            s.section(:name=>_("Correlation matrix for %s") % name) do |s2|
              s2.parse_element(correlation_matrix)
            end
          end
          if summary_pca
            s.section(:name=>_("PCA for %s") % name) do |s2|
              s2.parse_element(pca)
            end
          end
          if summary_principal_axis
            s.section(:name=>_("Principal Axis for %s") % name) do |s2|
              s2.parse_element(principal_axis_analysis)
            end
          end          
        end
      end
    end
  end
end