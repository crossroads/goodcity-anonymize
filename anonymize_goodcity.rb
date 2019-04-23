require 'data-anonymization'
require 'pg'
require './utils/string'
require './cloudinary'
require './inventory'

DataAnon::Utils::Logging.logger.level = Logger::INFO
logger = Logger.new(STDOUT)

args      = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
db_source = args['db-source'];
db_output = db_source + '_anonymized_' + Time.now.to_i.to_s
username  = args.fetch('username', 'postgres');
password  = args.fetch('password', '');
host      = args.fetch('host', 'localhost');
port      = args.fetch('port', 5432);
connection_options = { host: host, port: port, user: username, password: password }

test_images = Cloudinary.list_folder('test')['resources'].map{ |r| "#{r['version']}/#{r['public_id']}.#{r['format']}" }

if db_source.blank?
  puts 'Error missing source database'
  puts 'Usage: '
  puts "  ruby anonymize.rb --db-source=<database> [--host=<host>] [--port=<port>] [--username=<db user>] [--password=<db password]\n"
  exit 1
end

# Connect to generic PostgreSQL server
logger.info("Terminating database connections")
conn = PG.connect(host: 'localhost', port: 5432, user: username, password: password, dbname: nil)

conn.exec <<-SQL
  SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity
  WHERE pg_stat_activity.datname = '#{db_source}' AND pid <> pg_backend_pid();
SQL

logger.info("Copying source database")
conn.exec <<-SQL
  CREATE DATABASE #{db_output} WITH TEMPLATE #{db_source} OWNER #{username};
SQL
conn.close

# Reconnect to new database
logger.info("Beginning anonymization")
conn = PG.connect( connection_options.merge(dbname: db_output) )
conn.exec('TRUNCATE TABLE auth_tokens;')
conn.close

database 'Goodcity' do
  strategy DataAnon::Strategy::Blacklist
  # execution_strategy DataAnon::Parallel::Table

  connection_spec = {
    :adapter => 'postgresql',
    :host => 'localhost',
    :port => 5432,
    :pool => 5,
    :username => username,
    :password => password,
    :database => db_output
  }

  source_db connection_spec

  # CHECKED OK
  table 'addresses' do
    primary_key 'id'
    anonymize('street').using FieldStrategy::LoremIpsum.new
    anonymize('flat').using FieldStrategy::RandomAddress.region_UK
    anonymize('building').using FieldStrategy::StringTemplate.new('B#{row_number}')
  end

  # CHECKED OK
  table 'beneficiaries' do
    primary_key 'id'
    anonymize 'identity_number'
    anonymize('first_name').using FieldStrategy::StringTemplate.new('John#{row_number}')
    anonymize('last_name').using FieldStrategy::StringTemplate.new('Doe#{row_number}')
    anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
    anonymize('title') { ['Mr', 'Mrs', 'Ms'].sample }
  end

  # CHECKED OK
  table 'boxes' do
    primary_key 'id'
    anonymize('comments').using FieldStrategy::LoremIpsum.new
    anonymize('description').using FieldStrategy::LoremIpsum.new
  end

  # CHECKED OK
  table 'contacts' do
    primary_key 'id'
    anonymize('name').using FieldStrategy::RandomFullName.new
    anonymize('mobile').using FieldStrategy::RandomPhoneNumber.new
  end

  # CHECKED OK
  table 'gogovan_orders' do
    primary_key 'id'
    anonymize('driver_license')
    anonymize('driver_mobile').using FieldStrategy::RandomPhoneNumber.new
    anonymize('driver_name').using FieldStrategy::RandomFullName.new
    anonymize('booking_id') { nil }
    anonymize('ggv_uuid') { nil }
  end

  # CHECKED OK
  table 'goodcity_requests' do
    primary_key 'id'
    anonymize('description').using FieldStrategy::LoremIpsum.new
  end

  # CHECKED OK
  table 'images' do
    primary_key 'id'
    anonymize('cloudinary_id') { test_images.sample }
    anonymize('angle') { 0 }
  end

  # CHECKED OK
  table 'items' do
    primary_key 'id'
    anonymize('donor_description').using FieldStrategy::LoremIpsum.new
    anonymize('reject_reason').using FieldStrategy::LoremIpsum.new
    anonymize('rejection_comments').using FieldStrategy::LoremIpsum.new
  end

  # CHECKED OK
  table 'messages' do
    primary_key 'id'
    anonymize('body').using FieldStrategy::LoremIpsum.new
  end

  # CHECKED OK
  table 'offers' do
    primary_key 'id'
    anonymize 'origin', 'estimated_size'
    anonymize('cancel_reason').using FieldStrategy::LoremIpsum.new
    anonymize('notes').using FieldStrategy::LoremIpsum.new
  end

  # CHECKED OK
  table 'orders' do
    primary_key 'id'
    anonymize('purpose_description').using FieldStrategy::LoremIpsum.new
    anonymize('description').using FieldStrategy::LoremIpsum.new
    anonymize('code') { |field| Inventory.anonymize_designation_name(field.value) }
    anonymize('status') { nil }
    anonymize('cancellation_reason').using FieldStrategy::LoremIpsum.new
    anonymize('staff_note').using FieldStrategy::LoremIpsum.new
    anonymize('country_id').using FieldStrategy::SelectFromDatabase.new("countries", "id", connection_spec)
  end

  # CHECKED OK
  table 'organisations' do
    primary_key 'id'
    anonymize('name_en').using FieldStrategy::StringTemplate.new('Organisation #{row_number}')
    anonymize('name_zh_tw').using FieldStrategy::StringTemplate.new('Organisation ZH-TW #{row_number}')
    anonymize('description_en').using FieldStrategy::LoremIpsum.new
    anonymize('description_zh_tw').using FieldStrategy::LoremIpsum.new
    anonymize('registration') { nil }
    anonymize('website').using FieldStrategy::RandomUrl.new
    anonymize('country_id').using FieldStrategy::SelectFromDatabase.new("countries", "id", connection_spec)
    anonymize('gih3_id') { nil }
  end

  # CHECKED OK
  table 'organisations_users' do
    primary_key 'id'
    anonymize 'position'
    anonymize('preferred_contact_number').using FieldStrategy::RandomPhoneNumber.new
  end

  # Checked OK
  table 'packages' do
    primary_key 'id'
    anonymize('case_number') { |field| Inventory.random_case_number }
    anonymize('notes').using FieldStrategy::LoremIpsum.new
    anonymize('inventory_number') { |field| Inventory.anonymize_inventory_number(field.value) }
    anonymize('designation_name') { |field| Inventory.anonymize_designation_name(field.value) }
  end

  # Checked OK
  table 'pallets' do
    primary_key 'id'
    anonymize('description').using FieldStrategy::LoremIpsum.new
    anonymize('comments').using FieldStrategy::LoremIpsum.new
  end

  # Checked OK
  table 'stockit_contacts' do
    primary_key 'id'
    anonymize('first_name').using FieldStrategy::RandomFirstName.new
    anonymize('last_name').using FieldStrategy::RandomLastName.new
    anonymize('mobile_phone_number').using FieldStrategy::RandomPhoneNumber.new
    anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
  end

  # Checked OK
  table 'stockit_local_orders' do
    primary_key 'id'
    anonymize('hkid_number') { nil }
    anonymize('reference_number') { nil }
    anonymize('client_name').using FieldStrategy::RandomFullName.new
    anonymize('purpose_of_goods').using FieldStrategy::LoremIpsum.new
  end

  # Checked OK
  table 'stockit_organisations' do
    primary_key 'id'
    anonymize('name').using FieldStrategy::StringTemplate.new('Organisation #{row_number}')
  end

  # Checked OK
  table 'users' do
    primary_key 'id'
    anonymize('first_name').using FieldStrategy::RandomFirstName.new
    anonymize('last_name').using FieldStrategy::RandomLastName.new
    anonymize('mobile') { Inventory.random_hk_mobile }
    anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
    anonymize('email').using FieldStrategy::RandomMailinatorEmail.new
    anonymize('image_id') { nil }
    anonymize('sms_reminder_sent_at') { Time.now }
  end

end

conn = PG.connect( connection_options.merge(dbname: db_output) )
logger.info('Anonymizing versions...')
conn.exec('UPDATE versions SET object=NULL, object_changes=NULL')
logger.info("Vacuuming database...")
conn.exec('VACUUM (FULL, ANALYZE)');

conn.close

logger.info("Dumping database to ./goodcity_anonymized.dump")
cmd = "export PGPASSWORD=#{password};"
cmd += "pg_dump --host localhost --port 5432 --username #{username} --verbose --clean --no-owner --no-acl #{db_output} > ./goodcity_anonymized.dump"
exec cmd
