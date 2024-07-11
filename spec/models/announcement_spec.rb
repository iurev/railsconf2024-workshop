# frozen_string_literal: true

require 'rails_helper'

describe Announcement do
  describe 'Scopes' do
    context 'with published and unpublished records' do
      let_it_be(:published) { Fabricate(:announcement, published: true) }
      let_it_be(:unpublished) { Fabricate(:announcement, published: false, scheduled_at: 10.days.from_now) }

      describe '#unpublished' do
        it 'returns records with published false' do
          results = described_class.unpublished

          expect(results).to eq([unpublished])
        end
      end

      describe '#published' do
        it 'returns records with published true' do
          results = described_class.published

          expect(results).to eq([published])
        end
      end
    end

    context 'with timestamped announcements' do
      let_it_be(:adam_announcement) { Fabricate(:announcement, starts_at: 100.days.ago, scheduled_at: 10.days.ago, published_at: 10.days.ago, ends_at: 5.days.from_now) }
      let_it_be(:brenda_announcement) { Fabricate(:announcement, starts_at: 10.days.ago, scheduled_at: 100.days.ago, published_at: 10.days.ago, ends_at: 5.days.from_now) }
      let_it_be(:clara_announcement) { Fabricate(:announcement, starts_at: 10.days.ago, scheduled_at: 10.days.ago, published_at: 100.days.ago, ends_at: 5.days.from_now) }
      let_it_be(:darnelle_announcement) { Fabricate(:announcement, starts_at: 10.days.ago, scheduled_at: 10.days.ago, published_at: 10.days.ago, ends_at: 5.days.from_now, created_at: 100.days.ago) }

      describe '#chronological' do
        it 'orders the records correctly' do
          results = described_class.chronological

          expect(results).to eq(
            [
              adam_announcement,
              brenda_announcement,
              clara_announcement,
              darnelle_announcement,
            ]
          )
        end
      end

      describe '#reverse_chronological' do
        it 'orders the records correctly' do
          results = described_class.reverse_chronological

          expect(results).to eq(
            [
              darnelle_announcement,
              clara_announcement,
              brenda_announcement,
              adam_announcement,
            ]
          )
        end
      end
    end
  end

  describe 'Validations' do
    describe 'text' do
      it 'validates presence of attribute' do
        record = Fabricate.build(:announcement, text: nil)

        expect(record).to_not be_valid
        expect(record.errors[:text]).to be_present
      end
    end

    describe 'ends_at' do
      it 'validates presence when starts_at is present' do
        record = Fabricate.build(:announcement, starts_at: 1.day.ago)

        expect(record).to_not be_valid
        expect(record.errors[:ends_at]).to be_present
      end

      it 'does not validate presence when starts_at is missing' do
        record = Fabricate.build(:announcement, starts_at: nil)

        expect(record).to be_valid
        expect(record.errors[:ends_at]).to_not be_present
      end
    end
  end

  describe '#publish!' do
    it 'publishes an unpublished record' do
      announcement = Fabricate(:announcement, published: false, scheduled_at: 10.days.from_now)

      announcement.publish!

      expect(announcement).to be_published
      expect(announcement.published_at).to_not be_nil
      expect(announcement.scheduled_at).to be_nil
    end
  end

  describe '#unpublish!' do
    it 'unpublishes a published record' do
      announcement = Fabricate(:announcement, published: true)

      announcement.unpublish!

      expect(announcement).to_not be_published
      expect(announcement.scheduled_at).to be_nil
    end
  end

  describe '#reactions' do
    context 'with announcement_reactions present' do
      let_it_be(:account_reaction_emoji) { Fabricate(:custom_emoji) }
      let_it_be(:other_reaction_emoji) { Fabricate(:custom_emoji) }
      let_it_be(:account) { Fabricate(:account) }
      let_it_be(:announcement) { Fabricate(:announcement) }

      before do
        Fabricate(:announcement_reaction, announcement: announcement, created_at: 10.days.ago, name: other_reaction_emoji.shortcode)
        Fabricate(:announcement_reaction, announcement: announcement, created_at: 5.days.ago, account: account, name: account_reaction_emoji.shortcode)
        Fabricate(:announcement_reaction) # For some other announcement
      end

      it 'returns the announcement reactions for the announcement' do
        results = announcement.reactions

        expect(results).to have_attributes(
          size: eq(2),
          first: have_attributes(name: other_reaction_emoji.shortcode, me: false),
          last: have_attributes(name: account_reaction_emoji.shortcode, me: false)
        )
      end

      it 'returns the announcement reactions for the announcement with `me` set correctly' do
        results = announcement.reactions(account)

        expect(results).to have_attributes(
          size: eq(2),
          first: have_attributes(name: other_reaction_emoji.shortcode, me: false),
          last: have_attributes(name: account_reaction_emoji.shortcode, me: true)
        )
      end
    end
  end

  describe '#statuses' do
    let_it_be(:status) { Fabricate(:status, visibility: :public) }
    let_it_be(:direct_status) { Fabricate(:status, visibility: :direct) }

    context 'with empty status_ids' do
      let(:announcement) { Fabricate(:announcement, status_ids: nil) }

      it 'returns empty array' do
        results = announcement.statuses

        expect(results).to eq([])
      end
    end

    context 'with relevant status_ids' do
      let(:announcement) { Fabricate(:announcement, status_ids: [status.id, direct_status.id]) }

      it 'returns public and unlisted statuses' do
        results = announcement.statuses

        expect(results).to include(status)
        expect(results).to_not include(direct_status)
      end
    end
  end
end