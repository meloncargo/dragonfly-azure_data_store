RSpec.describe Dragonfly::AzureDataStore do
  let(:app) { Dragonfly.app }
  let(:datastore) do
    Dragonfly::AzureDataStore.new(
      account_name: 'dragonfly-test',
      container_name: 'test',
      access_key: 'abcde',
      root_path: 'folder'
    )
  end
  let(:container) do
    instance_double('Azure::Storage::Blob::Container::Container', name: 'test')
  end
  let(:response) do
    r = instance_double('Azure::Core::Http::HttpResponse')
    allow(r).to receive(:uri)
    allow(r).to receive(:status_code)
    allow(r).to receive(:reason_phrase)
    allow(r).to receive(:body)
    r
  end
  let(:metadata) { {} }
  let(:storage) do
    s = instance_double('Azure::Storage::Blob::BlobService')
    allow(s).to receive(:create_block_blob)
    allow(s).to receive(:delete_blob) do |_container_name, uid|
      raise(Azure::Core::Http::HTTPError, response) if uid =~ /not_found\.file/
    end
    allow(s).to receive(:get_blob) do |_container_name, uid|
      raise(Azure::Core::Http::HTTPError, response) if uid =~ /not_found\.file/
      [instance_double('Azure::Storage::Blob::Blob', metadata: metadata),
       'file content']
    end
    allow(s).to receive(:get_container_properties).and_return(container)
    allow(s).to receive(:create_container).and_return(container)
    s
  end

  before do
    allow_any_instance_of(Dragonfly::AzureDataStore).to receive(:storage).and_return(storage)
    allow_any_instance_of(Dragonfly::AzureDataStore).to receive(:rand).and_return(1234)
    allow(Time).to receive(:now).and_return(Time.new(2018, 2, 11))
  end

  describe 'registering with a symbol' do
    it 'registers a symbol for configuring' do
      app.configure do
        datastore :azure
      end
      expect(app.datastore).to be_a(Dragonfly::AzureDataStore)
    end
  end

  describe '.read' do
    let(:uid) { '2018/02/11/ya_test.txt' }

    subject { datastore.read(uid) }

    it { is_expected.to eq ['file content', {}] }

    context 'not found file' do
      let(:uid) { 'not_found.file' }
      it { is_expected.to be_nil }
    end

    context 'with metadata' do
      let(:metadata) do
        {
          'name' => 'image.png',
          'model_class' => 'Attachment',
          'model_attachment' => 'file'
        }
      end

      it { is_expected.to include metadata }
    end
  end

  describe '.write' do
    let(:opts) { {} }
    let(:content) do
      Dragonfly::Content.new(app, 'file content', 'name' => 'test.txt')
    end

    subject { datastore.write(content, opts) }

    it { is_expected.to eq '2018/02/11/ya_test.txt' }
  end

  describe '.destroy' do
    let(:uid) { '2018/02/11/ya_test.txt' }

    subject { datastore.destroy(uid) }

    it { is_expected.to be_truthy }

    context 'not found file' do
      let(:uid) { 'not_found.file' }
      it { is_expected.to be_falsey }
    end
  end

  describe '.url_for' do
    let(:uid) { 'some/path/on/azure' }
    let(:opts) { {} }

    subject { datastore.url_for(uid, opts) }

    it { is_expected.to eq 'http://dragonfly-test.blob.core.windows.net/test/folder/some/path/on/azure' }

    context 'with custom host' do
      context 'as part of class attributes' do
        before { datastore.url_host = 'another-url.com' }
        it { is_expected.to eq 'http://another-url.com/test/folder/some/path/on/azure' }
      end

      context 'as parameter' do
        let(:opts) { { host: 'another-url.com' } }
        it { is_expected.to eq 'http://another-url.com/test/folder/some/path/on/azure' }
      end
    end

    context 'with custom scheme' do
      context 'as part of class attributes' do
        before { datastore.url_scheme = 'https' }
        it { is_expected.to eq 'https://dragonfly-test.blob.core.windows.net/test/folder/some/path/on/azure' }
      end

      context 'as parameter' do
        let(:opts) { { scheme: 'https' } }
        it { is_expected.to eq 'https://dragonfly-test.blob.core.windows.net/test/folder/some/path/on/azure' }
      end
    end
  end
end
