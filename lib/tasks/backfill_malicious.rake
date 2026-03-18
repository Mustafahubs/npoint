namespace :documents do
  desc "Backfill flagged_malicious for all existing documents"
  task backfill_malicious: :environment do
    pattern = '^\s*\(?\s*function\s*\('
    batch_size = 5000
    flagged = 0

    min_id = Document.minimum(:id) || 0
    max_id = Document.maximum(:id) || 0

    (min_id..max_id).step(batch_size) do |start_id|
      end_id = start_id + batch_size - 1

      result = ActiveRecord::Base.connection.execute(<<-SQL)
        UPDATE documents
        SET flagged_malicious = true
        WHERE id BETWEEN #{start_id.to_i} AND #{end_id.to_i}
          AND NOT flagged_malicious
          AND jsonb_typeof(contents) = 'object'
          AND EXISTS (
            SELECT 1 FROM jsonb_each_text(contents) AS kv(key, value)
            WHERE kv.value ~ '#{pattern}'
          )
        RETURNING id, token
      SQL

      result.each do |row|
        puts "FLAGGED: id=#{row['id']} token=#{row['token']}"
        flagged += 1
      end

      puts "Processed IDs #{start_id}..#{end_id}"
    end

    puts "\nDone. Flagged #{flagged} documents."
  end
end
