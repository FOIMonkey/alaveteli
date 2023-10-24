namespace :temp do
  desc 'Migrate PublicBody#disclosure_log to translation model'
  task migrate_disclosure_log: :environment do
    class PublicBodyWithoutTranslations < ApplicationRecord # :nodoc:
      self.table_name = 'public_bodies'

      def with_translation
        AlaveteliLocalization.with_default_locale { PublicBody.find(id) }
      end
    end

    scope = PublicBodyWithoutTranslations.where.not(disclosure_log: nil)
    count = scope.count

    scope.find_each.with_index do |pb, index|
      pb.with_translation.update(disclosure_log: pb.disclosure_log)

      erase_line
      print "Migrate PublicBody#disclosure_log to " \
        "PublicBody::Translation#disclosure_log #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating to PublicBody::Translation#disclosure_log completed."
  end

  desc 'Migrate current User#url_name to new slug model'
  task migrate_user_slugs: :environment do
    scope = User.left_joins(:slugs).where(slugs: { id: nil })
    count = scope.count

    scope.find_each.with_index do |user, index|
      user.slugs.create!(slug: user.url_name)

      erase_line
      print "Migrate User#url_name to User#slugs #{index + 1}/#{count}"
    end

    erase_line
    puts "Migrating to User#slugs completed."
  end

  desc 'Populate OutgoingMessage#from_name'
  task populate_outgoing_message_from_name: :environment do
    scope = OutgoingMessage.where(from_name: nil).includes(:user)
    count = scope.count

    scope.find_each.with_index do |outgoing_message, index|
      user = outgoing_message.user
      name = user.read_attribute(:name)
      outgoing_message.update_columns(from_name: name)

      erase_line
      print "Populating OutgoingMessage#from_name #{index + 1}/#{count}"
    end

    erase_line
    puts "Populating OutgoingMessage#from_name completed."
  end

  def erase_line
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Escape_sequences
    print "\e[1G\e[K"
  end
end
