require "fileutils"
require "securerandom"
require "yaml"
require "active_support/encrypted_configuration"

namespace :setup do
  desc "One-shot install: bundle, postgres role, credentials, db, puma-dev"
  task :install do
    app_root = Rails.root.to_s

    puts "== bundle install =="
    unless system("bundle check")
      system("bundle install") || abort("bundle install failed")
    end

    puts "\n== postgres role =="
    Rake::Task["setup:db_role"].invoke

    puts "\n== credentials =="
    Rake::Task["setup:credentials"].invoke

    puts "\n== database =="
    unless system({ "RAILS_ENV" => "development" }, "bin/rails", "db:prepare", chdir: app_root)
      abort("db:prepare failed")
    end

    puts "\n== puma-dev =="
    Rake::Task["setup:puma_dev"].invoke

    puts <<~DONE

      == done ==
      App ready at https://signpost.test
      Add API keys at https://signpost.test/settings (GitHub, Slack, OpenAI, Anthropic)
      Background workers (Solid Queue + Slack listener): bin/workers
    DONE
  end

  desc "Create the signpost postgres role if missing"
  task :db_role do
    role_sql = <<~SQL
      DO $$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'signpost') THEN
          CREATE ROLE signpost WITH LOGIN PASSWORD 'signpost_dev' CREATEDB SUPERUSER;
          RAISE NOTICE 'created role signpost';
        ELSE
          RAISE NOTICE 'role signpost already exists';
        END IF;
      END $$;
    SQL
    unless system("psql", "postgres", "-c", role_sql)
      abort("psql failed - is Postgres running? (Postgres.app should be open)")
    end
  end

  desc "Generate master.key and seed credentials with db password + encryption keys"
  task :credentials do
    app_root = Rails.root.to_s
    master_key_path = File.join(app_root, "config/master.key")
    creds_path = File.join(app_root, "config/credentials.yml.enc")

    unless File.exist?(master_key_path)
      File.write(master_key_path, SecureRandom.hex(16))
      File.chmod(0o600, master_key_path)
      puts "  wrote config/master.key (0600)"
    end

    encrypted = ActiveSupport::EncryptedConfiguration.new(
      config_path: creds_path,
      key_path: master_key_path,
      env_key: "RAILS_MASTER_KEY",
      raise_if_missing_key: true,
    )

    existing = (encrypted.config || {}).deep_stringify_keys
    changed = false

    existing["database"] ||= {}
    if existing["database"]["password"].blank?
      existing["database"]["password"] = "signpost_dev"
      changed = true
      puts "  set database.password"
    end

    existing["active_record_encryption"] ||= {}
    %w[primary_key deterministic_key key_derivation_salt].each do |key|
      next if existing["active_record_encryption"][key].present?
      existing["active_record_encryption"][key] = SecureRandom.alphanumeric(32)
      changed = true
    end
    puts "  set active_record_encryption keys" if changed

    if changed
      encrypted.write(YAML.dump(existing))
      puts "  wrote config/credentials.yml.enc"
    else
      puts "  credentials already populated, skipping"
    end
  end

  desc "Symlink this app into ~/.puma-dev/signpost"
  task :puma_dev do
    unless system("command -v puma-dev > /dev/null 2>&1")
      puts "  puma-dev binary not found. Install with:"
      puts "    brew install puma/puma/puma-dev"
      puts "    sudo puma-dev -setup"
      puts "    puma-dev -install"
      puts "  Then re-run: bin/rails setup:puma_dev"
      next
    end

    app_root = Rails.root.to_s
    link = File.expand_path("~/.puma-dev/signpost")
    FileUtils.mkdir_p(File.dirname(link))
    FileUtils.ln_sf(app_root, link)
    puts "  linked #{link} -> #{app_root}"
  end
end
