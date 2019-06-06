# frozen_string_literal: true

RSpec.describe ActiveRecordPostgresqlXverify::Utils do
  specify 'pg_ping succeed' do
    expect(ActiveRecordPostgresqlXverify::Utils.pg_ping(@pg)).to be_truthy
  end

  specify 'pg_ping fails' do
    @pg.finish
    expect(ActiveRecordPostgresqlXverify::Utils.pg_ping(@pg)).to be_falsey
  end
end
