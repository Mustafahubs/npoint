namespace :documents do
  desc "Backfill flagged_malicious for all existing documents"
  task backfill_malicious: :environment do
    total = Document.count
    flagged = 0
    batch = 0

    Document.find_each(batch_size: 1000) do |doc|
      batch += 1
      if doc.content_looks_malicious?
        doc.update_column(:flagged_malicious, true)
        flagged += 1
        puts "FLAGGED: id=#{doc.id} token=#{doc.token}"
      end
      print "." if batch % 100 == 0
    end

    puts "\nDone. Scanned #{total} documents, flagged #{flagged}."
  end
end
