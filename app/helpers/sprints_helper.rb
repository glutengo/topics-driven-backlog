module SprintsHelper
  include ApplicationHelper

  def create_sprint_collection(duration, start_date, end_date)
    sprints = []
    days = (start_date...end_date).count + 1
    number_of_sprints = days/duration

    number_of_sprints.times do |i|
      end_date = start_date + duration.days - 1.days
      sprint = @course.sprints.create!(
          { :name => "#{i+1}. Sprint",
            :start_date => start_date,
            :end_date => end_date
          }
      )
      sprints.append(sprint)
      start_date = end_date + 1.days
    end

    create_sprint_plannings(sprints, @course)
    sprints
  end

  def update_sprint_collection(collection, course)
    sprints = []

    ActiveRecord::Base.transaction do
      collection.each do |s|
        validate_sprint_date_parameter(s[:start_date], s[:end_date])
        sprint = Sprint.find_by!(id: s[:id])
        sprint_params = s.permit(:start_date, :end_date, :name, :topic_ids => [])
        validate_topics(sprint_params[:topic_ids], course)

        sprint.update!(sprint_params)
        sprints.append(sprint)
      end
    end

    sprints
  end

  def validate_sprint_collection_params(start_date, end_date, duration)
    errors = []

    errors.append(
        duration_cannot_be_empty(duration)
    )
    errors.append(
        valid_date_range(start_date, end_date)
    )

    raise_exception_on_validation_error(errors)
  end

  def validate_sprint_date_parameter(start_date, end_date)
    if end_date.present? || start_date.present?

      errors = []

      errors.append(
          valid_date_range(start_date || '', end_date || '')
      )
      errors.append(
          ends_in_the_future(end_date || '')
      )

      raise_exception_on_validation_error(errors)
    end
  end

  def validate_topics(topic_ids, course)
    errors = []

    if topic_ids.present?

      topic_ids = filter_unique_parameter_list(topic_ids)

      topic_ids.each do |topic_id|
        errors.append(
            valid_topic_id(topic_id, course)
        )
      end

      raise_exception_on_validation_error(errors)
    end

  end

  private

  def filter_unique_parameter_list(list)
    list.uniq
  end

  def valid_topic_id(topic_id, course)
    if Topic.find_by(id: topic_id).nil?
      'Topic ' + topic_id.to_s + ' does not exist'
    else
      if Topic.find_by(id: topic_id).course != course
      'Topic ' + topic_id.to_s + ' does not exists for course ' + course.id.to_s
      end
    end
  end

  def duration_cannot_be_empty(duration)
    if duration == 0 || duration.blank?
      'Duration must be at least 1'
    end
  end

  def valid_date_range(start_date, end_date)
    if end_date.empty? || start_date.empty?
      return 'Start date or end date cannot be empty'
    end

    if end_date < start_date
      'End date cannot be before the start date'
    end
  end

  def ends_in_the_future(end_date)
    if !end_date.empty?
      if Date.parse(end_date) < Date.today
        'End date cannot be in the past'
      end
    end
  end

  def create_sprint_plannings(sprints, course)
    course.projects.each do |project|
      sprints.each do |sprint|
        project.sprint_plannings.create(sprint_id: sprint.id, planned: false)
      end
    end

  end
end
