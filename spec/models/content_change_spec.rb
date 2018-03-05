RSpec.describe ContentChange do
  subject { create(:content_change) }

  shared_examples "not travel advice" do
    it "is not recognised as travel advice" do
      expect(subject.is_travel_advice?).to be false
    end
  end

  shared_examples "travel advice" do
    it "is recognised as travel advice" do
      expect(subject.is_travel_advice?).to be true
    end
  end

  shared_examples "not medical safety alert" do
    it "is not recognised as medical safety alert" do
      expect(subject.is_medical_safety_alert?).to be false
    end
  end

  shared_examples "medical safety alert" do
    it "is recognised as medical safety alert" do
      expect(subject.is_medical_safety_alert?).to be true
    end
  end

  it_behaves_like "not travel advice"
  it_behaves_like "not medical safety alert"

  describe "#mark_processed!" do
    it "sets processed_at" do
      Timecop.freeze do
        expect { subject.mark_processed! }
          .to change(subject, :processed_at)
          .from(nil)
          .to(Time.now)
      end
    end
  end

  context "with a travel advice" do
    subject { create(:content_change, :travel_advice) }

    it_behaves_like "travel advice"
    it_behaves_like "not medical safety alert"
  end

  context "with a medical safety alert" do
    subject { create(:content_change, :medical_safety_alert) }

    it_behaves_like "not travel advice"
    it_behaves_like "medical safety alert"
  end
end
