require 'data-anonymization'
require 'pg'
require './inventory'

DataAnon::Utils::Logging.logger.level = Logger::INFO

args      = Hash[ ARGV.join(' ').scan(/--?([^=\s]+)(?:=(\S+))?/) ]
db_source = args['db-source'];
db_output = '__anonymized_si_' + Time.now.to_i.to_s
username  = args.fetch('username', 'postgres');
password  = args.fetch('password', '');

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

conn.exec <<-SQL
  DROP TABLE computers_os_backup_20150515;
SQL

conn.exec <<-SQL
  DROP TABLE item_casenumber_backup_20150509;
SQL

conn.exec <<-SQL
  DROP TABLE items_test;
SQL

conn.exec <<-SQL
  DROP TABLE js_computers_os_clean_test;
SQL

conn.exec <<-SQL
  DROP TABLE locals_stocktake_2013_04_16;
SQL

conn.exec <<-SQL
  DROP TABLE organisation_duplicates;
SQL

conn.exec <<-SQL
  DELETE FROM delayed_jobs;
SQL

conn.exec <<-SQL
  DELETE FROM images;
SQL

conn.close

begin
  database 'Goodcity' do
    strategy DataAnon::Strategy::Blacklist
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
      anonymize 'description', 'contents'
    end

    table 'carry_outs' do
      primary_key 'id'
      anonymize('staff_name').using FieldStrategy::RandomFullName.new
    end

    table 'computer_accessories' do
      primary_key 'id'
      anonymize('brand').using { nil }
      anonymize('model').using { nil }
      anonymize('serial_num').using { nil }
      anonymize('printer').using { nil }
      anonymize('scanner').using { nil }
      anonymize('interface').using { nil }
      anonymize('comp_voltage').using { nil }
      anonymize('comp_test_status').using { nil }
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
        'ms_ms_office_serial_num'
      ].each do |field|
        anonymize(field).using { nil }
      end
    end

    table 'contacts' do
      primary_key 'id'
      anonymize('first_name').using FieldStrategy::RandomFirstName.new
      anonymize('last_name').using FieldStrategy::RandomLstName.new
      anonymize('position') { 'queen' }
      anonymize('address_building') { 'Woodstock estate' }
      anonymize('address_street') { '42 Rock avenue'}
      anonymize('address_suburb') { 'Earth' }
      anonymize('phone_number').using FieldStrategy::RandomPhoneNumber.new
      anonymize('mobile_phone_number').using FieldStrategy::RandomPhoneNumber.new
      anonymize('alternative_phone_number').using FieldStrategy::RandomPhoneNumber.new
      anonymize('email').using FieldStrategy::StringTemplate.new('fake@email.com')
      anonymize('fax_number').using FieldStrategy::RandomPhoneNumber.new
      anonymize('perferred_communication_method') { 'phone' }
      anonymize('notes')
    end

    table 'delayed_jobs' do
      primary_key 'id'
      anonymize('name').using FieldStrategy::RandomFullName.new
      anonymize('mobile').using FieldStrategy::RandomPhoneNumber.new
    end

    table 'departments' do
      primary_key 'id'
      anonymize 'next_inventory_number'
    end

    table 'designation_requests' do
      primary_key 'id'
      anonymize('comments').using FieldStrategy::LoremIpsum.new
      anonymize('item_requested').using FieldStrategy::LoremIpsum.new
    end

    table 'designations' do
      primary_key 'id'
      anonymize('comments').using FieldStrategy::LoremIpsum.new
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

  cmd = "export PGPASSWORD=#{password};"
  cmd += "pg_dump --host localhost --port 5432 --username #{username} --verbose --clean --no-owner --no-acl #{db_output} > ./stockit_anonymized.dump"
  exec cmd
ensure
  conn =  PG.connect 'localhost', 5432, nil, nil, nil, username, password
  conn.exec "DROP DATABASE #{db_output}"
  conn.close
end