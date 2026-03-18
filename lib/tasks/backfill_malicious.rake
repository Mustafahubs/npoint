namespace :documents do
  desc "Backfill flagged_malicious for all existing documents"
  task backfill_malicious: :environment do
    pattern = '^\s*\(?\s*function\s*\('

    result = ActiveRecord::Base.connection.execute(<<-SQL)
      UPDATE documents
      SET flagged_malicious = true
      WHERE NOT flagged_malicious
        AND jsonb_typeof(contents) = 'object'
        AND EXISTS (
          SELECT 1 FROM jsonb_each_text(contents) AS kv(key, value)
          WHERE kv.value ~ '#{pattern}'
        )
      RETURNING id, token
    SQL

    result.each do |row|
      puts "FLAGGED: id=#{row['id']} token=#{row['token']}"
    end

    puts "\nDone. Flagged #{result.count} documents."
  end
end
