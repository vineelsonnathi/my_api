module API

  class GoogleAnalytics

    class << self

      def analyticsGet(dimensions, metrics, start_date, end_date, max_records=10)
        params = {}
        map_dimensions_and_metrics(dimensions,metrics)
        request_errors = validate_params(@dimensions, @metrics)
        response = if !request_errors[:error].present? # If dimensions and errors are present, does not check for invalid dimensions or metrics
          query_api(params.deep_merge!({dimensions: @dimensions, metrics: @metrics, start_date: start_date, end_date: end_date, max_records: max_records}))
        else
          request_errors[:error]
        end
      end

      def map_dimensions_and_metrics(d,m)
        @dimensions = d.map{|s| s.start_with?("ga:") ? s : s.prepend("ga:")}
        @metrics = m.map{|s| s.start_with?("ga:") ? s : s.prepend("ga:")}
      end

      def query_api(params)
        response = API::GoogleApi.execute_query(params)
        return response if response.success? # if the request is success, then return complete response
        return response.error_message if response.error? # if the request has errors, then return the exact error message
      end

      # This method validates whether dimensions and metrics are present
      def validate_params(dimensions, metrics)
        params = {}
        params[:error] = if dimensions.size < 1 && metrics.size < 1
          "Dimensions and Metrics are required. Input atleast one dimension and one metric"
        elsif dimensions.size < 1
          "Dimension is required. Input atleast one dimension"
        elsif metrics.size < 1
          "Metric is required. Input atleast one metric"
        end
        params
      end

    end
  end
end