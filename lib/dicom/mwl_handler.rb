# frozen_string_literal: true

module DICOM
  class MWLHandler
    def initialize(link, segments)
      @link = link
      @segments = segments
    end

    def process
      files, transfer_syntaxes = @link.handle_segments(@segments)
      messages = []
      success = false

      m_q  = files.first
      if m_q.length > 8
        dcm = DObject.parse(m_q, signature: false, no_meta: true, syntax: transfer_syntaxes.first)
        if dcm.read?
          success = true
          handle_query(dcm.to_hash.reject{ |k,_v| k == 'Transfer Syntax UID' })
        else
          messages << [:error, "Invalid DICOM data encountered: The received string was not parsed successfully."]
        end
      else
        messages << [:error, "Invalid data encountered: The received string was too small to contain any DICOM data."]
      end

      @link.handle_response("0000,0800" => NO_DATA_SET_PRESENT, "0000,0900" => SUCCESS)
      return success, messages
    end

    private

    def handle_query(query)

      puts "searching by: #{query}"

      items = [
        ['1.2.826.0.1.3680043.8.641.1.00111', 'szpitalik', 'pacjencik'],
        ['1.2.826.0.1.3680043.8.641.1.00222', 'szpitalik', 'pacjencik'],
        ['1.2.826.0.1.3680043.8.641.1.00333', 'szpitalik', 'pacjencik']
      ]
      items.each { |i| send_mwl_response(i) }
    end

    def send_mwl_response(item)
      @link.handle_response("0000,0800" => DATA_SET_PRESENT, "0000,0900" => PENDING)
      resp = DObject.new
      resp.add_element('0020,000D', item[0])
      resp.add_element('0008,0080', item[1])
      resp.add_element('0010,0010', item[2])
      @link.perform_send([resp])
    end
  end
end
