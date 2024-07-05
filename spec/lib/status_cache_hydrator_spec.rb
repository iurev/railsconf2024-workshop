# frozen_string_literal: true

require 'rails_helper'

describe StatusCacheHydrator do
  let_it_be(:account) { Fabricate(:account) }
  let_it_be(:status)  { Fabricate(:status) }

  describe '#hydrate' do
    let(:compare_to_hash) { InlineRenderer.render(status, account, :status) }

    shared_examples 'shared behavior' do
      context 'when handling a new status' do
        let_it_be(:poll) { Fabricate(:poll) }
        let_it_be(:status) { Fabricate(:status, poll: poll) }

        it 'renders the same attributes as a full render' do
          expect(subject).to eql(compare_to_hash)
        end
      end

      context 'when handling a new status with own poll' do
        let_it_be(:poll) { Fabricate(:poll, account: account) }
        let_it_be(:status) { Fabricate(:status, poll: poll, account: account) }

        it 'renders the same attributes as a full render' do
          expect(subject).to eql(compare_to_hash)
        end
      end

      context 'when handling a filtered status' do
        let_it_be(:status) { Fabricate(:status, text: 'this toot is about that banned word') }

        before_all do
          account.custom_filters.create!(phrase: 'filter1', context: %w(home), action: :hide, keywords_attributes: [{ keyword: 'banned' }, { keyword: 'irrelevant' }])
        end

        it 'renders the same attributes as a full render' do
          expect(subject).to eql(compare_to_hash)
        end
      end

      context 'when handling a reblog' do
        let_it_be(:reblog) { Fabricate(:status) }
        let_it_be(:status) { Fabricate(:status, reblog: reblog) }

        context 'when it has been favourited' do
          before_all do
            FavouriteService.new.call(account, reblog)
          end

          it 'renders the same attributes as a full render' do
            expect(subject).to eql(compare_to_hash)
          end
        end

        context 'when it has been reblogged' do
          before_all do
            ReblogService.new.call(account, reblog)
          end

          it 'renders the same attributes as a full render' do
            expect(subject).to eql(compare_to_hash)
          end
        end

        context 'when it has been pinned' do
          let_it_be(:reblog) { Fabricate(:status, account: account) }

          before_all do
            StatusPin.create!(account: account, status: reblog)
          end

          it 'renders the same attributes as a full render' do
            expect(subject).to eql(compare_to_hash)
          end
        end

        context 'when it has been followed tags' do
          let_it_be(:followed_tag) { Fabricate(:tag) }

          before_all do
            reblog.tags << Fabricate(:tag)
            reblog.tags << followed_tag
            TagFollow.create!(tag: followed_tag, account: account, rate_limit: false)
          end

          it 'renders the same attributes as a full render' do
            expect(subject).to eql(compare_to_hash)
          end
        end

        context 'when it has a poll authored by the user' do
          let_it_be(:poll) { Fabricate(:poll, account: account) }
          let_it_be(:reblog) { Fabricate(:status, poll: poll, account: account) }

          it 'renders the same attributes as a full render' do
            expect(subject).to eql(compare_to_hash)
          end
        end

        context 'when it has been voted in' do
          let_it_be(:poll) { Fabricate(:poll, options: %w(Yellow Blue)) }
          let_it_be(:reblog) { Fabricate(:status, poll: poll) }

          before_all do
            VoteService.new.call(account, poll, [0])
          end

          it 'renders the same attributes as a full render' do
            expect(subject).to eql(compare_to_hash)
          end
        end

        context 'when it matches account filters' do
          let_it_be(:reblog) { Fabricate(:status, text: 'this toot is about that banned word') }

          before_all do
            account.custom_filters.create!(phrase: 'filter1', context: %w(home), action: :hide, keywords_attributes: [{ keyword: 'banned' }, { keyword: 'irrelevant' }])
          end

          it 'renders the same attributes as a full render' do
            expect(subject).to eql(compare_to_hash)
          end
        end
      end
    end

    context 'when cache is warm' do
      subject do
        Rails.cache.write("fan-out/#{status.id}", InlineRenderer.render(status, nil, :status))
        described_class.new(status).hydrate(account.id)
      end

      it_behaves_like 'shared behavior'
    end

    context 'when cache is cold' do
      subject do
        Rails.cache.delete("fan-out/#{status.id}")
        described_class.new(status).hydrate(account.id)
      end

      it_behaves_like 'shared behavior'
    end
  end
end