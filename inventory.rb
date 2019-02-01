require 'hashids'

secret = ENV['ANONYMIZE_SECRET']

if secret.nil?
  raise <<-HEREDOC
    Error:
    Anonymization secret no configured. Please set the following environment variable : ANONYMIZE_SECRET 
  HEREDOC
end

hashids = Hashids.new(secret)

class Inventory
  def self.anonymize_code(code)
    return code if code.blank?

    first_letter = code[0]
    if first_letter =~ /[a-z]/i
      code = code[1..-1]
    else
      first_letter = ''
    end

    code = code.tr('^0-9', '');
    seed = hashids.encode(code).hash
    srand(seed);
    len = code.length;
    new_code = first_letter + rand((10**(len-1))..(10**len)).to_s
    new_code
  end
end