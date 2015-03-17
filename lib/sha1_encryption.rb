module Sha1Encryption
  def self.encrypt(plain_password, salt, offset=-1)
    bytes = plain_password.each_char.inject(''){ |bytes, c| bytes + c + "\x00" }
    concat = Base64.decode64(salt).force_encoding('utf-8')[0..offset] + bytes
    sha1 = Digest::SHA1.digest concat
    Base64.encode64(sha1).strip
  end
end
