# frozen_string_literal: true

RSpec.describe ActiveRecordPostgresqlXverify do
  let(:called) { {} }

  let(:verify) do
    lambda do |_|
      called[:verify] = true
      false
    end
  end

  let(:handle_if) do
    lambda do |_|
      called[:handle_if] = true
      true
    end
  end

  let(:only_on_error) { false }

  before do
    ActiveRecordPostgresqlXverify.verify = verify
    ActiveRecordPostgresqlXverify.handle_if = handle_if
    ActiveRecordPostgresqlXverify.only_on_error = only_on_error
  end

  context 'when verification fails' do
    it 'is reconnecting' do
      expect(ActiveRecordPostgresqlXverify.logger).to receive(:info).with(
        /Invalid connection: host=[^,]+, database=[^,]+, username=\S+/
      ).twice

      expect(Book.count).to be_zero
      prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

      active_record_release_connections

      expect(Book.count).to be_zero
      curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
      expect(curr_process_id).to_not eq prev_process_id

      expect(called[:verify]).to be_truthy
      expect(called[:handle_if]).to be_truthy
    end

    context 'with prepared statements' do
      it 'is reconnecting' do
        expect(ActiveRecordPostgresqlXverify.logger).to receive(:info).with(
          /Invalid connection: host=[^,]+, database=[^,]+, username=\S+/
        ).once

        expect(Book.connection.prepared_statements).to be_truthy

        expect(Book.find_by_id(-1)).to be_nil
        prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

        active_record_release_connections

        expect(Book.find_by_id(-1)).to be_nil
        curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
        expect(curr_process_id).to_not eq prev_process_id

        expect(called[:verify]).to be_truthy
        expect(called[:handle_if]).to be_truthy
      end
    end
  end

  context 'when verification succeeds' do
    let(:verify) do
      lambda do |_|
        called[:verify] = true
        true
      end
    end

    it 'does not reconnect' do
      expect(ActiveRecordPostgresqlXverify.logger).to_not receive(:info)

      expect(Book.count).to be_zero
      prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

      active_record_release_connections

      expect(Book.count).to be_zero
      curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
      expect(curr_process_id).to eq prev_process_id

      expect(called[:verify]).to be_truthy
      expect(called[:handle_if]).to be_truthy
    end

    context 'with prepared statements' do
      it 'is reconnecting' do
        expect(Book.connection.prepared_statements).to be_truthy

        expect(Book.find_by_id(-1)).to be_nil
        prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

        active_record_release_connections

        expect(Book.find_by_id(-1)).to be_nil
        curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
        expect(curr_process_id).to eq prev_process_id

        expect(called[:verify]).to be_truthy
        expect(called[:handle_if]).to be_truthy
      end
    end
  end

  context 'when only_on_error is true' do
    let(:only_on_error) { true }

    context 'when SQL execution is normal' do
      it 'does not reconnect' do
        expect(ActiveRecordPostgresqlXverify.logger).to_not receive(:info)

        expect(Book.count).to be_zero
        prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

        active_record_release_connections

        expect(Book.count).to be_zero
        curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
        expect(curr_process_id).to eq prev_process_id

        expect(called[:verify]).to be_falsey
        expect(called[:handle_if]).to be_falsey
      end
    end

    context 'when SQL execution is abnormal' do
      context 'when verification fails' do
        it 'is reconnecting' do
          expect(ActiveRecordPostgresqlXverify.logger).to receive(:info).with(
            /Invalid connection: host=[^,]+, database=[^,]+, username=\S+/
          ).twice

          # execute
          expect { Book.connection.execute('INVALID SQL') }.to raise_error(ActiveRecord::StatementInvalid)
          prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

          active_record_release_connections

          expect(Book.count).to be_zero
          curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
          expect(curr_process_id).to_not eq prev_process_id

          # exec_query
          expect { Book.connection.exec_query('INVALID SQL') }.to raise_error(ActiveRecord::StatementInvalid)
          prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

          active_record_release_connections

          expect(Book.count).to be_zero
          curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
          expect(curr_process_id).to_not eq prev_process_id

          expect(called[:verify]).to be_truthy
          expect(called[:handle_if]).to be_truthy
        end
      end

      context 'when verification succeeds' do
        let(:verify) do
          lambda do |_|
            called[:verify] = true
            true
          end
        end

        it 'does not reconnect' do
          expect(ActiveRecordPostgresqlXverify.logger).to_not receive(:info)

          # execute
          expect { Book.connection.execute('INVALID SQL') }.to raise_error(ActiveRecord::StatementInvalid)
          prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

          active_record_release_connections

          expect(Book.count).to be_zero
          curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
          expect(curr_process_id).to eq prev_process_id

          # exec_query
          expect { Book.connection.exec_query('INVALID SQL') }.to raise_error(ActiveRecord::StatementInvalid)
          prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

          active_record_release_connections

          expect(Book.count).to be_zero
          curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
          expect(curr_process_id).to eq prev_process_id

          expect(called[:verify]).to be_truthy
          expect(called[:handle_if]).to be_truthy
        end
      end
    end
  end

  context 'when not handled' do
    let(:handle_if) do
      lambda do |_|
        called[:handle_if] = true
        false
      end
    end

    it 'does not reconnect' do
      expect(ActiveRecordPostgresqlXverify.logger).to_not receive(:info)

      expect(Book.count).to be_zero
      prev_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)

      active_record_release_connections

      expect(Book.count).to be_zero
      curr_process_id = Book.connection.query('select pg_backend_pid()').first.fetch(0)
      expect(curr_process_id).to eq prev_process_id

      expect(called[:verify]).to be_falsey
      expect(called[:handle_if]).to be_truthy
    end
  end
end
