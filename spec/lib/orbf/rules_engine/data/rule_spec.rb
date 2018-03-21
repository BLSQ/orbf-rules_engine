
RSpec.describe Orbf::RulesEngine::Rule do


    it "verifies kind" do
        expect {
        described_class.new(kind: "unknown")
        }.to raise_error 'Invalid rule kind \'unknown\' only supports ["activity", "package", "zone", "payment", "entities_aggregation"]'
    end
end