require 'rails_helper'

RSpec.describe 'Sprints API' do

  let(:user) { create(:user) }
  let!(:course) { create(:course) }
  before(:each) do
    course.instructions.build( user_id: user.id, initial_instructor: true )
    course.save!
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authorize_request).and_return(user)
  end

  let(:course_id) { course.id }
  let!(:sprint_1) {
    create(:sprint, course_id: course.id, start_date: Date.new(2018,11,07), end_date: Date.new(2018,11,17))
  }
  let!(:sprint_2) {
    create(:sprint, course_id: course.id, start_date: Date.new(2018,11,17), end_date: Date.new(2018,11,27))
  }
  let(:id) { sprint_1.id }

  # Test suite for PUT /sprints/:id
  describe 'PUT /sprints/:id' do
    let(:valid_attributes) {
      {
          name: 'Learn Elm',
          start_date: Date.today.to_s,
          end_date: Date.tomorrow.to_s
      }
    }
    before { put "/sprints/#{id}", params: valid_attributes }

    context 'when the record exists' do
      it 'updates the record' do
        expect(json).not_to be_empty
        expect(json['name']).to eq('Learn Elm')
        expect(json['start_date']).to eq(Date.today.to_s)
        expect(json['end_date']).to eq(Date.tomorrow.to_s)
        expect(json['course_id']).to eq(course_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Sprint/)
      end
    end
  end

  # Test suite for PATCH /sprints/:id
  describe 'PATCH /sprints/:id for date attributes' do
    let(:valid_date_attributes) {
      { start_date: Date.today.to_s, end_date: Date.tomorrow.to_s }
    }
    let(:invalid_dates_attribute) {
      { start_date: Date.tomorrow.to_s, end_date: Date.today.to_s }
    }

    context 'updating a valid end date' do
      before { patch "/sprints/#{id}", params: valid_date_attributes }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'updating an invalid end date' do
      before { patch "/sprints/#{id}", params: invalid_dates_attribute }

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: End date cannot be before the start date/)
      end
    end

    context 'updating dates to the past' do
      before { patch "/sprints/#{id}", params:
          { start_date: Date.new(2017,10,1).to_s, end_date: Date.new(2017,10,8).to_s }
      }

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
      end

      it 'returns a failure message' do
        expect(response.body).to match(/Validation failed: End date cannot be in the past/)
      end
    end
  end

  # Test suite for DELETE /sprints/:id
  describe 'DELETE /sprints/:id' do
    before { delete "/sprints/#{id}"}

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

end