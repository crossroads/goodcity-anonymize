require 'data-anonymization'
require 'pg'
require './inventory'

DataAnon::Utils::Logging.logger.level = Logger::INFO

args      = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
db_source = args['db-source'];
db_output = db_source + '_anonymized_' + Time.now.to_i.to_s
username  = args.fetch('username', 'postgres');
password  = args.fetch('password', '');
host      = args.fetch('host', 'localhost');
port      = args.fetch('port', 5432);
connection_options = { host: host, port: port, user: username, password: password }

if db_source.blank?
  puts 'Error missing source database'
  puts 'Usage: '
  puts "  ruby anonymize.rb --db-source=<database> [--host=<host>] [--port=<port>] [--username=<db user>] [--password=<db password]\n"
  exit 1
end

# Open generic connection to Postgres DB server
conn = PG.connect(connection_options)

conn.exec <<-SQL
  SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity
  WHERE pg_stat_activity.datname = '#{db_source}' AND pid <> pg_backend_pid();
SQL

conn.exec <<-SQL
  CREATE DATABASE #{db_output} WITH TEMPLATE #{db_source} OWNER #{username};
SQL

conn.close

# Switch to new database
conn = PG.connect( connection_options.merge(dbname: db_output) )
conn.exec('DROP TABLE computers_os_backup_20150515;')
conn.exec('DROP TABLE item_casenumber_backup_20150509;')
conn.exec('DROP TABLE items_test;')
conn.exec('DROP TABLE js_computers_os_clean_test;')
conn.exec('DROP TABLE locals_stocktake_2013_04_16;')
conn.exec('DROP TABLE organisation_duplicates;')
conn.exec('DELETE FROM delayed_jobs;')
conn.exec('DELETE FROM images;')
conn.close


database 'Goodcity' do
  strategy DataAnon::Strategy::Blacklist
  execution_strategy DataAnon::Parallel::Table
  
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

  table 'boxes' do
    primary_key 'id'
    anonymize 'description', 'contents', 'comments'
  end

  table 'carry_outs' do
    primary_key 'id'
    anonymize('staff_name').using FieldStrategy::RandomFullName.new
  end

  table 'computer_accessories' do
    primary_key 'id'
    anonymize('brand') { nil }
    anonymize('model') { nil }
    anonymize('serial_num') { nil }
    anonymize('printer') { nil }
    anonymize('scanner') { nil }
    anonymize('interface') { nil }
    anonymize('comp_voltage') { nil }
    anonymize('comp_test_status') { nil }
    anonymize('size') { nil }
  end

  table 'computers' do
    primary_key 'id'
    [
      'brand',
      'model',
      'serial_num',
      'size',
      'cpu',
      'socket',
      'fsb',
      'ram',
      'floppy',
      'hdd',
      'zip',
      'optical',
      'video',
      'sound',
      'lan',
      'wireless',
      'modem',
      'scsi',
      'tv_tuner',
      'usb',
      'firewire',
      'interface',
      'comp_voltage',
      'comp_test_status',
      'os',
      'os_serial_num',
      'ms_office_serial_num',
      'mar_os_serial_num',
      'mar_ms_office_serial_num',
    ].each do |field|
      anonymize(field) { nil }
    end
  end

  #country

  table 'contacts' do
    primary_key 'id'
    anonymize('first_name').using FieldStrategy::RandomFirstName.new
    anonymize('last_name').using FieldStrategy::RandomLastName.new
    anonymize('position') { 'queen' }
    anonymize('address_building') { 'Woodstock estate' }
    anonymize('address_street') { '42 Rock avenue'}
    anonymize('address_suburb') { 'Earth' }
    anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
    anonymize('mobile_phone_number').using FieldStrategy::RandomPhoneNumber.new
    anonymize('alternative_phone_number').using FieldStrategy::RandomPhoneNumber.new
    anonymize('email').using FieldStrategy::StringTemplate.new('fake@example.com')
    anonymize('fax_number').using FieldStrategy::RandomPhoneNumber.new
    anonymize('perferred_communication_method') { 'phone' }
    anonymize('notes')
  end

  table 'country' do
    primary_key 'id'
    anonymize('name_en').using FieldStrategy::SelectFromDatabase.new('countries','name_en', connection_spec)
    anonymize('name_ru') { nil }
    anonymize('name_zh') { nil }
  end

  table 'designation_requests' do
    primary_key 'id'
    anonymize('comments').using FieldStrategy::LoremIpsum.new
    anonymize('item_requested').using FieldStrategy::LoremIpsum.new
  end

  table 'designations' do
    primary_key 'id'
    anonymize('comments').using FieldStrategy::LoremIpsum.new
    anonymize('description').using FieldStrategy::LoremIpsum.new
    anonymize('code') { |field| Inventory.anonymize_code(field.value) }
  end

  table 'electricals' do
    primary_key 'id'
    anonymize 'brand', 'model', 'serial_number', 'standard', 'voltage', 'frequency', 'power',
      'system_or_region'
    anonymize('test_status') { 'passed' }
  end

  table 'items' do
    primary_key 'id'
    anonymize 'pat_device_serial_number', 'case_number'
    anonymize('inventory_number') { |field| Inventory.anonymize_code(field.value) }
    anonymize('description').using FieldStrategy::LoremIpsum.new
    anonymize('comments').using FieldStrategy::LoremIpsum.new
    anonymize('image_path') { nil }
    anonymize('image_id') { nil }
    anonymize('pat_test_status') { 'passed '}
  end

  table 'local_orders' do
    primary_key 'id'
    anonymize 'reference_number'
    anonymize('staff_name').using FieldStrategy::RandomFirstName.new
    anonymize('purpose_of_goods').using FieldStrategy::LoremIpsum.new
    anonymize('follow_up_visit_comment').using FieldStrategy::LoremIpsum.new
    anonymize('cancelled_comment').using FieldStrategy::LoremIpsum.new
    anonymize('client_name').using FieldStrategy::RandomFirstName.new
    anonymize('hkid_number') { 'M000000(0)' }
  end

  table 'medicals' do
    primary_key 'id'
    anonymize 'brand', 'model', 'entered_by_user'
    anonymize('package_description').using FieldStrategy::LoremIpsum.new
    anonymize('comments').using FieldStrategy::LoremIpsum.new
  end

  table 'organisations' do
    primary_key 'id'
    anonymize 'name'
    anonymize('website') { 'http://sample.com' }
    anonymize('registration') { nil }
    anonymize('description').using FieldStrategy::LoremIpsum.new
    anonymize('name_zh') { nil }
  end

  table 'packages' do
    primary_key 'id'
    anonymize('package_description').using FieldStrategy::LoremIpsum.new
    anonymize('comments').using FieldStrategy::LoremIpsum.new
  end

  table 'pallets' do
    primary_key 'id'
    anonymize('description').using FieldStrategy::LoremIpsum.new
    anonymize('comments').using FieldStrategy::LoremIpsum.new
  end

  table 'people' do
    primary_key 'id'
    anonymize('guid') { nil }
    anonymize('username').using FieldStrategy::StringTemplate.new('user_#{row_number}')
    anonymize('name').using FieldStrategy::StringTemplate.new('User #{row_number}')
  end

  table 'shipments' do
    primary_key 'id'
    anonymize('shipping_mark') { nil }
    anonymize('shipping_area') { nil }
    anonymize('shipping_country') { ['Beirut', 'Dakar', 'Istanbul', 'Hong Kong'].sample }
    anonymize('project_type') { nil }
    anonymize('container_ownership') { nil }
    anonymize('shipment_type') { nil }
    anonymize('cbm_type') { nil }
    anonymize('transport_cost') { nil }
  end
end

# Reconnect and vacuum to recover disk space and optimize query planner
Logger.info("Vacuuming database...")
conn = PG.connect( connection_options.merge(dbname: db_output) )
conn.exec('VACUUM (FULL, ANALYZE)');
conn.close

Logger.info("Dumping database to ./stockit_anonymized.dump")
cmd = "export PGPASSWORD=#{password};"
cmd += "pg_dump --host localhost --port 5432 --username #{username} --verbose --clean --no-owner --no-acl #{db_output} > ./stockit_anonymized.dump"
exec cmd

