require 'singleton'

class FakeSequencescapeService
  include Singleton

  def clear
    @search_results = {}
  end

  def search_results
    @search_results ||= {}
  end

  def search_result(search_uuid, barcode, result_json)
    search_results[search_uuid] = {} if search_results[search_uuid].nil?
    search_results[search_uuid][barcode] = result_json
  end

  def find_result_json_by_search_uuid(search_uuid, barcode)
    return nil unless search_results[search_uuid]
    search_results[search_uuid][barcode]
  end

  def load_file(filename)
    base_path = File.join(File.dirname(__FILE__), '..', 'data')
    json = IO.read(File.join(base_path, filename).to_s)
    replace_host_and_port(json)
  end

  def replace_host_and_port(json)
    uri = URI(Settings.sequencescape_api_v1)
    json.gsub(/localhost/, uri.host).gsub(/3000/, uri.port.to_s)
  end

  def self.install_hooks(target, tags)
    target.instance_eval do
      Before(tags) do |_scenario|
        Capybara.current_session.driver.browser if Capybara.current_driver == Capybara.javascript_driver
        api_url = Settings.sequencescape_api_v1
        api_dumb = 'http://sequencescape/api'

        stub_request(:get, api_url).to_return do
          json = FakeSequencescapeService.instance.load_file('index')
          FakeSequencescapeService.response_format(json)
        end

        stub_request(:post, "#{api_url}/asset_audits").to_return do
          json = FakeSequencescapeService.instance.load_file('create_asset_audit')
          FakeSequencescapeService.response_format(json, 201)
        end

        stub_request(:get, "#{api_url}/#{Settings.search_find_assets_by_barcode}").to_return do
          json = FakeSequencescapeService.instance.load_file('search_find_asset_by_barcode')
          FakeSequencescapeService.response_format(json)
        end

        stub_request(:post, "#{api_url}/#{Settings.search_find_assets_by_barcode}/all").to_return do
          json = FakeSequencescapeService.instance.find_result_json_by_search_uuid(
            Settings.search_find_assets_by_barcode,
            ActiveSupport::JSON.decode(request.body.read)['search']['barcode']
          )
          if json.blank?
            json = FakeSequencescapeService.instance.load_file('search_results_for_find_asset_by_barcode')
          end
          FakeSequencescapeService.response_format(json, 300)
        end

        stub_request(:get, "#{api_url}/#{Settings.search_find_source_assets_by_destination_barcode}").to_return do
          json = FakeSequencescapeService.instance.load_file('search_find_source_assets_by_destination_barcode')
          FakeSequencescapeService.response_format(json)
        end

        stub_request(:post, "#{api_url}/#{Settings.search_find_source_assets_by_destination_barcode}/all").to_return do
          json = FakeSequencescapeService.instance.find_result_json_by_search_uuid(
            Settings.search_find_source_assets_by_destination_barcode,
            ActiveSupport::JSON.decode(request.body.read)['search']['barcode']
          )
          FakeSequencescapeService.response_format(json, 300)
        end


        stub_request(:get, api_dumb).to_return do
          json = FakeSequencescapeService.instance.load_file('index')
          FakeSequencescapeService.response_format(json)
        end

        stub_request(:post, "#{api_dumb}/asset_audits").to_return do
          json = FakeSequencescapeService.instance.load_file('create_asset_audit')
          FakeSequencescapeService.response_format(json, 201)
        end

        stub_request(:get, "#{api_dumb}/#{Settings.search_find_assets_by_barcode}").to_return do
          json = FakeSequencescapeService.instance.load_file('search_find_asset_by_barcode')
          FakeSequencescapeService.response_format(json)
        end

        stub_request(:post, "#{api_dumb}/#{Settings.search_find_assets_by_barcode}/all").to_return do
          json = FakeSequencescapeService.instance.find_result_json_by_search_uuid(
            Settings.search_find_assets_by_barcode,
            ActiveSupport::JSON.decode(request.body.read)['search']['barcode']
          )
          if json.blank?
            json = FakeSequencescapeService.instance.load_file('search_results_for_find_asset_by_barcode')
          end
          FakeSequencescapeService.response_format(json, 300)
        end

        stub_request(:get, "#{api_dumb}/#{Settings.search_find_source_assets_by_destination_barcode}").to_return do
          json = FakeSequencescapeService.instance.load_file('search_find_source_assets_by_destination_barcode')
          FakeSequencescapeService.response_format(json)
        end

        stub_request(:post, "#{api_dumb}/#{Settings.search_find_source_assets_by_destination_barcode}/all").to_return do
          json = FakeSequencescapeService.instance.find_result_json_by_search_uuid(
            Settings.search_find_source_assets_by_destination_barcode,
            ActiveSupport::JSON.decode(request.body.read)['search']['barcode']
          )
          FakeSequencescapeService.response_format(json, 300)
        end


        # stub_request(:get, /http:\/\/sequencescape\/api\/.*/)
      end

      After(tags) do |_scenario|
        FakeSequencescapeService.instance.clear
      end
    end
  end

  private

  def self.response_format(body_value, status=200)
    {
      status: status,
      headers: { 'Content-Type': 'application/json' },
      body: body_value
    }
  end
end

FakeSequencescapeService.install_hooks(self, '@sequencescape_service')
