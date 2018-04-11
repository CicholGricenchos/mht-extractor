require 'base64'
mht = File.open('zzz.mht').read

class MhtExtractor
  class Part
    def initialize text
      @raw = text
    end

    def parse
      header, @body = @raw.split("\r\n\r\n")
      @headers = header.split("\r\n").map{|x|
        match_data = x.match(/(.+):\s*(.+)/)
        [match_data[1], match_data[2]] if match_data
      }.compact.to_h
    end

    def generate_file
      parse
      location = @headers['Content-Location'] || 'index.html'
      File.open(location, 'wb'){|f|
        case @headers['Content-Transfer-Encoding']
        when 'base64'
          f.write Base64.decode64(@body)
        else
          f.write @body
        end
      }
    end
  end

  def initialize text
    @raw = text

  end

  def read_boundary
    @raw.match(/boundary="(.+?)"/)[1]
  rescue
    raise "cannot read boundary"
  end

  def parts
    @raw.split(read_boundary)[2..-2].map{|x| Part.new(x)}
  end

  def generate_files
    parts.map(&:generate_file)
  end
end

MhtExtractor.new(mht).generate_files
