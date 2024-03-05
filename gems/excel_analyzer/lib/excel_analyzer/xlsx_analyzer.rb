require "active_storage"
require "active_storage/analyzer"

require "excel_analyzer/probe"

module ExcelAnalyzer
  ##
  # The Analyzer class is responsible for analyzing Excel (.xlsx) files uploaded
  # through Active Storage.
  #
  class XlsxAnalyzer < ActiveStorage::Analyzer
    include ExcelAnalyzer::Probe

    CONTENT_TYPE =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    def self.accept?(blob)
      blob.content_type == CONTENT_TYPE
    end

    def metadata
      data = excel_metadata

      if suspected_problem?(data)
        # rubocop:disable Style/RescueModifier
        ExcelAnalyzer.on_hidden_metadata.call(blob, data) rescue nil
        # rubocop:enable Style/RescueModifier
      end

      { excel: data }
    end

    private

    def excel_metadata
      download_blob_to_tempfile(&method(:probe))
    rescue StandardError => ex
      { error: ex.message }
    end

    def suspected_problem?(data)
      data.any? { |k, v| k != :error && k != :named_ranges && v > 1 }
    end
  end
end