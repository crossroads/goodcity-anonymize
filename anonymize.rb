require 'data-anonymization'
require 'pg'
require './cloudinary'

DataAnon::Utils::Logging.logger.level = Logger::INFO

args      = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
db_source = args['db-source'];
db_output = '__anonymized_' + Time.now.to_i.to_s
username  = args.fetch('username', 'postgres');
password  = args.fetch('password', '');

test_images = Cloudinary.list_folder('test')['resources'].map{ |r| "v#{r['version']}/#{r['public_id']}.#{r['format']}" }

class String
  def blank?
    nil? || empty?
  end
end

if db_source.blank?
  puts 'Error missing source database'
  puts 'Usage: '
  puts "  ruby anonymize.rb --db-source=<database> [--username=<db user>] [--password=<db password]\n"
  exit 1
end

conn    =  PG.connect 'localhost', 5432, nil, nil, nil, username, password

conn.exec <<-SQL
  SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity
  WHERE pg_stat_activity.datname = '#{db_source}' AND pid <> pg_backend_pid();
SQL

conn.exec <<-SQL
  CREATE DATABASE #{db_output} WITH TEMPLATE #{db_source} OWNER #{username};
SQL

conn.close

begin
  database 'Goodcity' do
    strategy DataAnon::Strategy::Blacklist
    source_db({
      :adapter => 'postgresql',
      :host => 'localhost',
      :port => 5432,
      :pool => 5,
      :username => username,
      :password => password,
      :database => db_output
    })

    table 'addresses' do
      primary_key 'id'
      anonymize 'street'
      anonymize('flat').using FieldStrategy::RandomAddress.region_UK
      anonymize('building').using FieldStrategy::StringTemplate.new('B#{row_number}')
    end

    table 'auth_tokens' do
      primary_key 'id'
      anonymize 'otp_secret_key', 'otp_auth_key'
    end

    table 'braintree_transactions' do
      primary_key 'id'
      anonymize 'transaction_id', 'customer_id', 'amount'
    end

    table 'beneficiaries' do
      primary_key 'id'
      anonymize 'identity_number'
      anonymize('first_name').using FieldStrategy::StringTemplate.new('John#{row_number}')
      anonymize('last_name').using FieldStrategy::StringTemplate.new('Doe#{row_number}')
      anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
    end

    table 'contacts' do
      primary_key 'id'
      anonymize('name').using FieldStrategy::RandomFullName.new
      anonymize('mobile').using FieldStrategy::RandomPhoneNumber.new
    end

    table 'images' do
      primary_key 'id'
      anonymize('cloudinary_id') { test_images.sample }
    end

    table 'messages' do
      primary_key 'id'
      anonymize('body').using FieldStrategy::RandomString.new
    end

    table 'stockit_contacts' do
      primary_key 'id'
      anonymize('first_name').using FieldStrategy::RandomFirstName.new
      anonymize('last_name').using FieldStrategy::RandomLastName.new
      anonymize('mobile_phone_number').using FieldStrategy::RandomPhoneNumber.new
      anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
    end

    table 'stockit_local_orders' do
      primary_key 'id'
      anonymize 'hkid_number', 'reference_number' # @Steve -> what's the reference number
      anonymize('client_name').using FieldStrategy::RandomFullName.new
    end

    table 'users' do
      primary_key 'id'
      anonymize('first_name').using FieldStrategy::RandomFirstName.new
      anonymize('last_name').using FieldStrategy::RandomLastName.new
      anonymize('mobile').using FieldStrategy::RandomPhoneNumber.new
      anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
      anonymize('email').using FieldStrategy::StringTemplate.new('fake@email.com')
    end


  end

  cmd = "export PGPASSWORD=#{password};"
  cmd += "pg_dump --host localhost --port 5432 --username #{username} --verbose --clean --no-owner --no-acl #{db_output} > ./goodcity_anonymized.dump"
  exec cmd
ensure
  conn =  PG.connect 'localhost', 5432, nil, nil, nil, username, password
  conn.exec "DROP DATABASE #{db_output}"
  conn.close
end