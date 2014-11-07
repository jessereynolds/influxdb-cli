require 'spec_helper'

module InfluxDBClient
  describe Client do
    describe '.QUERY_LANGUAGE_MATCHER' do
      subject { Client::QUERY_LANGUAGE_MATCHER }
      context 'when SELECT queries' do
        it { should match('SELECT value1, value2 FROM response_times') }
        it { should match('select * from response_times') }
        it { should match('SELECT * FROM series1, series2') }
        it { should match('SELECT * FROM series1, series2 LIMIT 1') }

        it { should_not match('SELECT value1, value2FROM response_times') }
        it { should_not match('select from response_times') }
        it { should_not match('SELECT * FROM') }
      end

      context 'when DELETE queries' do
        it { should match('DELETE FROM response_times') }
        it { should match('delete from series1, series2') }

        it { should_not match('DELETEFROM response_times') }
        it { should_not match('delete value1, value2 from series1, series2') }
        it { should_not match('DELETE * FROM series1, series2') }
      end
    end

    describe '.SWITCH_DATABASE_MATCHER' do
      subject { Client::SWITCH_DATABASE_MATCHER }
      it { should match('use response_times') }
      it { should match('  use   response_times  ') }

      it { should_not match('use') }
      it { should_not match(' use ') }
      it { should_not match('use response_times tests') }
      it { should_not match('useresponse_times') }
    end

    describe '.print_tabularize' do
      let(:result)  { { series1: [{ 'time' => 1387287723816, 'value1' => 1,   'value2' => 2 }],
                        series2: [{ 'time' => 1394552447955, 'value3' => 3,   'value4' => 4, 'value5' => nil, 'value6' => nil },
                                  { 'time' => 1394664358980, 'value3' => nil, 'value4' => 4, 'value5' => 5,   'value6' => 6   }] } }

      it 'generates tables' do
        expect(Terminal::Table).to receive(:new).
          with(title: :series1, headings: %w[time value1 value2], rows: [[1387287723816, 1, 2]])

        expect(Terminal::Table).to receive(:new).
          with(title: :series2, headings: %w[time value3 value4 value5 value6], rows: [[1394552447955, 3, 4, nil, nil], [1394664358980, nil, 4, 5, 6]])

        described_class.print_tabularize(result, :ms)
      end

      context 'when pretty' do
        before(:all) { described_class.pretty = true }
        after(:all)  { described_class.pretty = false }

        context 'and time precision is seconds' do
          let(:result)  { { series1: [{ 'time' => 1387287723, 'value1' => 1, 'value2' => 2 }] } }
          it 'generates tables' do
            expect(Terminal::Table).to receive(:new).
              with(title: :series1, headings: %w[time value1 value2], rows: [['2013-12-17 13:42:03', 1, 2]])
            
            described_class.print_tabularize(result, :s)
          end
        end

        context 'and time precision is milliseconds' do
          it 'generates tables' do
            expect(Terminal::Table).to receive(:new).
              with(title: :series1, headings: %w[time value1 value2], rows: [['2013-12-17 13:42:03.815', 1, 2]])

            expect(Terminal::Table).to receive(:new).
              with(title: :series2, headings: %w[time value3 value4 value5 value6], rows: [['2014-03-11 15:40:47.954', 3, 4, nil, nil], ['2014-03-12 22:45:58.980', nil, 4, 5, 6]])

            described_class.print_tabularize(result, :ms)
          end
        end

        context 'and time precision is microseconds' do
          let(:result)  { { series1: [{ 'time' => 1387287723816232, 'value1' => 1, 'value2' => 2 }] } }
          it 'generates tables' do
            expect(Terminal::Table).to receive(:new).
              with(title: :series1, headings: %w[time value1 value2], rows: [['2013-12-17 13:42:03.816231', 1, 2]])
            
            described_class.print_tabularize(result, :u)
          end
        end
        
      end

      it 'prints results' do
        output = double 'Output'
        table  = double 'Table'
        allow(Terminal::Table).to receive(:new).and_return(table)

        # should print series1 and series2
        expect(output).to receive(:puts).twice.with(table)
        # print results count
        expect(output).to receive(:puts).once.with('1 result found for series1')
        expect(output).to receive(:puts).once.with('2 results found for series2')
        # line break for series
        expect(output).to receive(:puts).twice.with(no_args)

        described_class.print_tabularize(result, :ms, output)
      end

      context 'when no results' do
        let(:result)  { { series1: [{ value1: 1, value2: 2 }],
                          series2: [] } }

        it 'prints generic no results found' do
          output = double 'Output'
          result = {}
          expect(output).to receive(:puts).once.with('No results found')
          described_class.print_tabularize(result, :ms, output)
        end

        it 'prints specific no results found per series' do
          output = double 'Output'
          table  = double 'Table'
          allow(Terminal::Table).to receive(:new).and_return(table)

          # should print series1
          expect(output).to receive(:puts).once.with(table)
          # print results count
          expect(output).to receive(:puts).once.with('1 result found for series1')
          # no results for series 2
          expect(output).to receive(:puts).once.with('No results found for series2')
          # line break for series
          expect(output).to receive(:puts).twice.with(no_args)

          described_class.print_tabularize(result, :ms, output)
        end
      end

      context 'when result is null' do
        it 'prints generic no results found' do
          output = double 'Output'
          result = nil
          expect(output).to receive(:puts).once.with('No results found')
          described_class.print_tabularize(result, :ms, output)
        end
      end
    end
  end
end
