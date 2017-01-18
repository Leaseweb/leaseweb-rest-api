class HashToURIConversion
  def to_params(hash)
    params = hash.map { |k, v| normalize_param(k, v) }.join
    params.chop! # trailing &
    params
  end

  def normalize_param(key, value)
    param = ''
    stack = []

    if value.is_a?(Array)
      param << value.each_with_index.map { |element, i| normalize_param("#{key}[#{i}]", element) }.join
    elsif value.is_a?(Hash)
      stack << [key, value]
    else
      param << "#{key}=#{URI.encode(value.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}&"
    end

    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          param << normalize_param("#{parent}[#{k}]", v)
        end
      end
    end

    param
  end
end
