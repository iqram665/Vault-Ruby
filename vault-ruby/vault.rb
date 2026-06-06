require 'openssl'
require 'json'
require 'fileutils'

class VaultRuby
  DATA_FILE = "vault_data.json"
  
  def initialize
    # A fixed secret key for password encryption (in Real App it is in environment variables)
    @cipher_key = "IqramulDevSecretKey1234567890123" # Must be 32 bytes
    @cipher_iv = "InitialVector123"                 # Must be 16 bytes
    setup_file
  end

  def setup_file
    unless File.exist?(DATA_FILE)
      File.write(DATA_FILE, JSON.generate({}))
    end
  end

  # Encrypt data function
  def encrypt(text)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.encrypt
    cipher.key = @cipher_key
    cipher.iv = @cipher_iv
    encrypted = cipher.update(text) + cipher.final
    encrypted.unpack1('H*') # Convert to hexadecimal
  end

  # Decrypt data function
  def decrypt(hex_text)
    cipher = OpenSSL::Cipher.new('AES-256-CBC')
    cipher.decrypt
    cipher.key = @cipher_key
    cipher.iv = @cipher_iv
    decrypted = cipher.update([hex_text].pack('H*')) + cipher.final
    decrypted
  rescue OpenSSL::Cipher::CipherError
    "Error: Invalid Data or Cipher!"
  end

  # Add a new password
  def add_password(platform, username, password)
    file_data = JSON.parse(File.read(DATA_FILE))
    
    encrypted_pass = encrypt(password)
    file_data[platform] = { "username" => username, "password" => encrypted_pass }
    
    File.write(DATA_FILE, JSON.pretty_generate(file_data))
    puts "\n🟩 [Success] Password for '#{platform}' saved securely!"
  end

  # Retrieve a password
  def get_password(platform)
    file_data = JSON.parse(File.read(DATA_FILE))
    
    if file_data.key?(platform)
      account = file_data[platform]
      decrypted_pass = decrypt(account["password"])
      
      puts "\n🔑 Account Details for #{platform}:"
      puts "--------------------------------"
      puts "👤 Username: #{account['username']}"
      puts "🔒 Password: #{decrypted_pass}"
      puts "--------------------------------"
    else
      puts "\n🟥 [Error] No password found for '#{platform}'"
    end
  end

  # List all secured platforms
  def list_platforms
    file_data = JSON.parse(File.read(DATA_FILE))
    if file_data.empty?
      puts "\n🟨 Your Vault is currently empty."
    else
      puts "\n📋 Secured Platforms inside Vault:"
      puts "--------------------------------"
      file_data.keys.each { |key| puts "🔹 #{key}" }
      puts "--------------------------------"
    end
  end
end

# CLI interface loop
vault = VaultRuby.new

puts "========================================"
puts "🛡️  WELCOME TO VAULT-RUBY CLI MANAGER 🛡️"
puts "========================================"

loop do
  puts "\nChoose an option:"
  puts "1. Add a new password"
  puts "2. Retrieve a password"
  puts "3. List all secured platforms"
  puts "4. Exit Vault"
  print "👉 Enter choice (1-4): "
  
  choice = gets.chomp.to_i

  case choice
  when 1
    print "Enter Platform (e.g., GitHub, Adobe): "
    platform = gets.chomp.downcase
    print "Enter Username/Email: "
    username = gets.chomp
    print "Enter Password: "
    password = gets.chomp
    vault.add_password(platform, username, password)
  when 2
    print "Enter Platform Name to search: "
    platform = gets.chomp.downcase
    vault.get_password(platform)
  when 3
    vault.list_platforms
  when 4
    puts "\n🔒 Vault Locked. Goodbye!"
    break
  else
    puts "\nInvalid choice! Please try again."
  end
end