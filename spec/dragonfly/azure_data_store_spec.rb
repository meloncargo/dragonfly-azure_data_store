RSpec.describe Dragonfly::AzureDataStore do
  let(:app) { Dragonfly.app }
  let(:content) { Dragonfly::Content.new(app, "eggheads") }
  let(:new_content) { Dragonfly::Content.new(app) }

  describe "registering with a symbol" do
    it "registers a symbol for configuring" do
      app.configure do
        datastore :azure
      end
      expect(app.datastore).to be_a(Dragonfly::AzureDataStore)
    end
  end

  describe "write" do
    it "should use the name from the content if set" do
      content.name = 'doobie.doo'
      uid = @data_store.write(content)
      uid.should =~ /doobie\.doo$/
      new_content.update(*@data_store.read(uid))
      new_content.data.should == 'eggheads'
    end

    it "should work ok with files with funny names" do
      content.name = "A Picture with many spaces in its name (at 20:00 pm).png"
      uid = @data_store.write(content)
      uid.should =~ /A Picture with many spaces in its name \(at 20:00 pm\)\.png/
      new_content.update(*@data_store.read(uid))
      new_content.data.should == 'eggheads'
    end

    it "should allow for setting the path manually" do
      uid = @data_store.write(content, :path => 'hello/there')
      uid.should == 'hello/there'
      new_content.update(*@data_store.read(uid))
      new_content.data.should == 'eggheads'
    end

    if enabled # Fog.mock! doesn't act consistently here
      it "should reset the connection and try again if Fog throws a socket EOFError" do
        @data_store.storage.should_receive(:put_object).exactly(:once).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        @data_store.storage.should_receive(:put_object).with(BUCKET_NAME, anything, anything, hash_including)
        @data_store.write(content)
      end

      it "should just let it raise if Fog throws a socket EOFError again" do
        @data_store.storage.should_receive(:put_object).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        @data_store.storage.should_receive(:put_object).and_raise(Excon::Errors::SocketError.new(EOFError.new))
        expect{
          @data_store.write(content)
        }.to raise_error(Excon::Errors::SocketError)
      end
    end
  end

  describe "urls for serving directly" do

    before(:each) do
      @uid = 'some/path/on/s3'
    end

    it "should use the bucket subdomain" do
      @data_store.url_for(@uid).should == "http://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should use path style if the bucket is not a valid S3 subdomain" do
      bucket_name = BUCKET_NAME.upcase
      @data_store.bucket_name = bucket_name
      @data_store.url_for(@uid).should == "http://s3.amazonaws.com/#{bucket_name}/some/path/on/s3"
    end

    it "should use the bucket subdomain for other regions too" do
      @data_store.region = 'eu-west-1'
      @data_store.url_for(@uid).should == "http://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should give an expiring url" do
      @data_store.url_for(@uid, :expires => 1301476942).should =~
        %r{^https://#{BUCKET_NAME}\.#{@data_store.domain}/some/path/on/s3\?.*X-Amz-Expires=}
    end

    it "should add query params" do
      @data_store.url_for(@uid, :expires => 1301476942, :query => {'response-content-disposition' => 'attachment'}).should =~
        %r{^https://#{BUCKET_NAME}\.#{@data_store.domain}/some/path/on/s3\?.*response-content-disposition=attachment}
    end

    it "should allow for using https" do
      @data_store.url_for(@uid, :scheme => 'https').should == "https://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should allow for always using https" do
      @data_store.url_scheme = 'https'
      @data_store.url_for(@uid).should == "https://#{BUCKET_NAME}.s3.amazonaws.com/some/path/on/s3"
    end

    it "should allow for customizing the host" do
      @data_store.url_for(@uid, :host => 'customised.domain.com/and/path').should == "http://customised.domain.com/and/path/some/path/on/s3"
    end

    it "should allow the url_host to be customised permanently" do
      url_host = 'customised.domain.com/and/path'
      @data_store.url_host = url_host
      @data_store.url_for(@uid).should == "http://#{url_host}/some/path/on/s3"
    end
  end
end
