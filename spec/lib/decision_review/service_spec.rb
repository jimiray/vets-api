# frozen_string_literal: true

require 'rails_helper'
require 'decision_review/service'

describe DecisionReview::Service do
  subject { described_class.new }

  let(:ssn_with_mockdata) { '212222112' }
  let(:user) { build(:user, :loa3, ssn: ssn_with_mockdata) }

  describe 'VetsJsonSchema used in service' do
    describe 'ensure HLR schemas are present' do
      %w[
        HLR-CREATE-REQUEST-BODY
        HLR-CREATE-REQUEST-HEADERS
        HLR-CREATE-RESPONSE-200
        HLR-CREATE-RESPONSE-422
        HLR-GET-CONTESTABLE-ISSUES-REQUEST-BENEFIT-TYPE
        HLR-GET-CONTESTABLE-ISSUES-REQUEST-HEADERS
        HLR-GET-CONTESTABLE-ISSUES-RESPONSE-200
        HLR-GET-CONTESTABLE-ISSUES-RESPONSE-404
        HLR-GET-CONTESTABLE-ISSUES-RESPONSE-422
        HLR-SHOW-RESPONSE-200
        HLR-SHOW-RESPONSE-404
      ].each do |schema_name|
        it("#{schema_name} schema is present") { expect(VetsJsonSchema::SCHEMAS[schema_name]).to be_a Hash }
      end
    end

    describe 'ensure HLR schema examples are present' do
      %w[
        HLR-CREATE-REQUEST-BODY
        HLR-CREATE-REQUEST-HEADERS
        HLR-CREATE-RESPONSE-200
        HLR-CREATE-RESPONSE-422
        HLR-GET-CONTESTABLE-ISSUES-REQUEST-HEADERS
        HLR-GET-CONTESTABLE-ISSUES-RESPONSE-200
        HLR-GET-CONTESTABLE-ISSUES-RESPONSE-404
        HLR-GET-CONTESTABLE-ISSUES-RESPONSE-422
        HLR-SHOW-RESPONSE-200
        HLR-SHOW-RESPONSE-404
      ].each do |schema_name|
        it("#{schema_name} schema example is present") { expect(VetsJsonSchema::EXAMPLES).to have_key schema_name }
      end
    end
  end

  describe '#create_higher_level_review_headers' do
    subject { described_class.new.send(:create_higher_level_review_headers, user) }

    let(:user) do
      name = 'x' * 100
      build :user, first_name: name, middle_name: name, last_name: name
    end

    it 'returns a properly formatted 200 response' do
      expect(subject['X-VA-First-Name']).to eq 'x' * 12
      expect(subject['X-VA-Middle-Initial']).to eq 'X'
      expect(subject['X-VA-Last-Name']).to eq 'x' * 18
    end
  end

  describe '#create_higher_level_review' do
    subject { described_class.new.create_higher_level_review(request_body: body.to_json, user: user) }

    let(:body) { VetsJsonSchema::EXAMPLES['HLR-CREATE-REQUEST-BODY'] }

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/HLR-CREATE-RESPONSE-200') do
          expect(subject).to respond_to :status
          expect(subject.status).to be 200
          expect(subject).to respond_to :body
          expect(subject.body).to be_a Hash
        end
      end
    end

    context '422 response' do
      let(:body) { {} }

      it 'throws a DR_422 exception' do
        VCR.use_cassette('decision_review/HLR-CREATE-RESPONSE-422') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_422'))
          )
        end
      end
    end

    context 'user is missing data' do
      before do
        allow_any_instance_of(User).to receive(:ssn).and_return(nil)
      end

      it 'throws a Common::Exceptions::Forbidden exception' do
        expect { subject }.to raise_error Common::Exceptions::Forbidden
      end
    end
  end

  describe '#create_notice_of_disagreement' do
    subject { described_class.new.create_notice_of_disagreement(request_body: body.to_json, user: user) }

    let(:body) do
      full_body = JSON.parse(File.read(
                               Rails.root.join('spec', 'fixtures', 'notice_of_disagreements',
                                               'valid_NOD_create_request.json')
                             ))
      full_body.delete('nodUploads')
      full_body
    end

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/NOD-CREATE-RESPONSE-200') do
          expect(subject).to respond_to :status
          expect(subject.status).to be 200
          expect(subject).to respond_to :body
          expect(subject.body).to be_a Hash
        end
      end
    end

    context '422 response' do
      let(:body) { {} }

      it 'throws a DR_422 exception' do
        VCR.use_cassette('decision_review/NOD-CREATE-RESPONSE-422') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_422'))
          )
        end
      end
    end

    context 'user is missing data' do
      before do
        allow_any_instance_of(User).to receive(:ssn).and_return(nil)
      end

      it 'throws a Common::Exceptions::Forbidden exception' do
        expect { subject }.to raise_error Common::Exceptions::Forbidden
      end
    end
  end

  describe '#get_higher_level_review' do
    subject { described_class.new.get_higher_level_review(uuid) }

    let(:uuid) { '75f5735b-c41d-499c-8ae2-ab2740180254' }

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/HLR-SHOW-RESPONSE-200') do
          expect(subject).to respond_to :status
          expect(subject.status).to be 200
          expect(subject).to respond_to :body
          expect(subject.body).to be_a Hash
        end
      end
    end

    context '404 response' do
      let(:uuid) { '0' }

      it 'throws a DR_404 exception' do
        VCR.use_cassette('decision_review/HLR-SHOW-RESPONSE-404') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_404'))
          )
        end
      end
    end
  end

  describe '#get_notice_of_disagreement' do
    subject { described_class.new.get_notice_of_disagreement(uuid) }

    let(:uuid) { '1234567a-89b0-123c-d456-789e01234f56' }

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/NOD-SHOW-RESPONSE-200') do
          expect(subject).to respond_to :status
          expect(subject.status).to be 200
          expect(subject).to respond_to :body
          expect(subject.body).to be_a Hash
        end
      end
    end

    context '404 response' do
      let(:uuid) { '0' }

      it 'throws a DR_404 exception' do
        VCR.use_cassette('decision_review/NOD-SHOW-RESPONSE-404') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_404'))
          )
        end
      end
    end
  end

  describe '#get_higher_level_review_contestable_issues' do
    subject do
      described_class.new.get_higher_level_review_contestable_issues(benefit_type: benefit_type, user: user)
    end

    let(:benefit_type) { 'compensation' }

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/HLR-GET-CONTESTABLE-ISSUES-RESPONSE-200') do
          expect(subject).to respond_to :status
          expect(subject.status).to be 200
          expect(subject).to respond_to :body
          expect(subject.body).to be_a Hash
        end
      end
    end

    context '200 response with a malformed body' do
      def personal_information_logs
        PersonalInformationLog.where error_class: 'DecisionReview::Service#validate_against_schema' \
          ' exception Common::Exceptions::SchemaValidationErrors (HLR)'
      end

      it 'returns a schema error' do
        VCR.use_cassette('decision_review/HLR-GET-CONTESTABLE-ISSUES-RESPONSE-200-MALFORMED') do
          expect(personal_information_logs.count).to be 0
          expect { subject }.to raise_error an_instance_of Common::Exceptions::SchemaValidationErrors
          expect(personal_information_logs.count).to be 1
        end
      end
    end

    context '404 response' do
      before do
        allow_any_instance_of(User).to receive(:ssn).and_return('000000000')
      end

      it 'throws a DR_404 exception' do
        VCR.use_cassette('decision_review/HLR-GET-CONTESTABLE-ISSUES-RESPONSE-404') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_404'))
          )
        end
      end
    end

    context '422 response' do
      let(:benefit_type) { 'apricot' }

      it 'throws a DR_422 exception' do
        VCR.use_cassette('decision_review/HLR-GET-CONTESTABLE-ISSUES-RESPONSE-422') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_422'))
          )
        end
      end
    end
  end

  describe '#get_notice_of_disagreement_contestable_issues' do
    subject do
      described_class.new.get_notice_of_disagreement_contestable_issues(user: user)
    end

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/NOD-GET-CONTESTABLE-ISSUES-RESPONSE-200') do
          expect(subject).to respond_to :status
          expect(subject.status).to be 200
          expect(subject).to respond_to :body
          expect(subject.body).to be_a Hash
        end
      end
    end

    context '200 response with a malformed body' do
      def personal_information_logs
        PersonalInformationLog.where error_class: 'DecisionReview::Service#validate_against_schema' \
          ' exception Common::Exceptions::SchemaValidationErrors (NOD)'
      end

      it 'returns a schema error' do
        VCR.use_cassette('decision_review/NOD-GET-CONTESTABLE-ISSUES-RESPONSE-200-MALFORMED') do
          expect(personal_information_logs.count).to be 0
          expect { subject }.to raise_error an_instance_of Common::Exceptions::SchemaValidationErrors
          expect(personal_information_logs.count).to be 1
        end
      end
    end

    context '404 response' do
      before do
        allow_any_instance_of(User).to receive(:ssn).and_return('000000000')
      end

      it 'throws a DR_404 exception' do
        VCR.use_cassette('decision_review/NOD-GET-CONTESTABLE-ISSUES-RESPONSE-404') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_404'))
          )
        end
      end
    end
  end

  describe '#get_notice_of_disagreement_upload_url' do
    subject do
      described_class.new.get_notice_of_disagreement_upload_url(nod_id: uuid)
    end

    context '200 response' do
      let(:uuid) { '6d0c3dba-8a1f-41be-bd16-59bf22d273e7' }

      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/NOD-GET-UPLOAD-URL-200') do
          expect(subject.status).to be 200
          expect(subject).to respond_to :body
          expect(subject.body).to be_a Hash
        end
      end
    end

    context '404 response' do
      let(:uuid) { 'this-id-not-found' }

      it 'throws a DR_404 exception' do
        VCR.use_cassette('decision_review/NOD-GET-UPLOAD-URL-404') do
          expect { subject }.to raise_error(
            an_instance_of(DecisionReview::ServiceException).and(having_attributes(key: 'DR_404'))
          )
        end
      end
    end
  end

  describe '#put_notice_of_disagreement_upload' do
    subject do
      described_class.new.put_notice_of_disagreement_upload(upload_url: path, file_path: file_path, metadata: metadata)
    end

    let(:file_path) { 'spec/fixtures/files/doctors-note.pdf' }
    let(:path) do
      'https://sandbox-api.va.gov/services_user_content/vba_documents/021d2fab-b3ca-4928-b90d-94b4c45529d8?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAQD72FDTFWPUWR5OZ/20210426/us-gov-west-1/s3/aws4_request&X-Amz-Date=20210426T163153Z&X-Amz-Expires=900&X-Amz-Signature=33e56786dfc1b5d6758abd931d9d50388f6206302708074b1924929c6e33da00&X-Amz-SignedHeaders=host'
    end
    let(:metadata) { { foo: 'bar' } }

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/NOD-PUT-UPLOAD-200') do
          expect(subject.status).to be 200
        end
      end
    end
  end

  describe '#get_notice_of_disagreement_upload' do
    subject do
      described_class.new.get_notice_of_disagreement_upload(guid: guid)
    end

    let(:guid) { '848134d0-1842-488a-b8bb-5e94d717b2c6' }

    context '200 response' do
      it 'returns a properly formatted 200 response' do
        VCR.use_cassette('decision_review/NOD-GET-UPLOAD-200') do
          expect(subject.status).to be 200
        end
      end
    end
  end
end
