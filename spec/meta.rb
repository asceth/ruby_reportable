RubyReportable.define :meta do
  source do
    as :object

    logic do
      ObjectSpace.each_object.to_a.group_by(&:class).to_a
    end
  end

  output('Class') { object.first.to_s }
  output('Total') { object.last.size }

end
