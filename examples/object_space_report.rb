class ObjectSpaceReport
  include RubyReportable

  #
  # Name the report
  #
  report 'Object Space By Class'

  #
  # Give the report a category for organization
  #
  category 'Object Reports'

  #
  # Define the data source
  #
  source do
    as :object

    logic do
      ObjectSpace.each_object.to_a.group_by(&:class).to_a
    end
  end

  #
  # Perform a final manipulation to the returned records like making sure all are unique
  #
  finalize
    source.all.uniq
  end

  #
  # Define output fields
  #
  output('Class') { object.first.to_s }
  output('Total') { object.last.size }

  #
  # Define a filter to help select which records to find
  #
  filter('Just These Objects') do
    priority 0
    key :just_these_objects
    require # Require an input for this filter

    input(:value) {}

    valid? do
      # Check to see if an input is present
      validity = !input.blank?
      !! validity
    end

    logic do
      # Perform some logic using the input
      source.where(["object = #{input}"])
    end
  end
end
