class RenameEsfaSubscriberList < ActiveRecord::Migration[5.2]
  def change
    SubscriberList.find_by(
      slug: "education-and-education-and-skills-funding-agency"
    ).update_attributes!(
      slug: "education-and-skills-funding-agency",
      title: "Education and Skills Funding Agency"
    )
  end
end
