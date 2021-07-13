module Etsy
  module V2
    class Response < BaseResponse
      def code
        @raw_response.code
      end

      def count
        if paginated?
          to_hash['results'].nil? ? 0 : to_hash['results'].size
        else
          to_hash['count']
        end
      end

      def success_result
        results = to_hash['results'] || []
        count == 1 ? results.first : results
      end

      def paginated?
        !!to_hash['pagination']
      end
    end
  end
end
