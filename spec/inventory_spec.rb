require 'spec_helper'
load 'inventory.rb'

context "Inventory#anonymize_inventory_number" do
  subject { Inventory.anonymize_inventory_number(inventory_number) }
  
  context 'anonymize_inventory_number' do
    context "F12345" do
      let(:inventory_number) { "F12345" }
      it do
        expect(subject).to start_with('F')
        expect(subject.length).to eql(7)
      end
    end

    context "X00123" do
      let(:inventory_number) { "X00123" }
      it do
        expect(subject).to start_with('X')
        expect(subject.length).to eql(7)
      end
    end

    context "F12345Q" do
      let(:inventory_number) { "F12345Q" }
      it do
        expect(subject).to start_with('F')
        expect(subject).to end_with('Q')
        expect(subject.length).to eql(8)
      end
    end

    context "F12345Q12" do
      let(:inventory_number) { "F12345Q12" }
      it do
        expect(subject).to start_with('F')
        expect(subject).to end_with('Q12')
        expect(subject.length).to eql(10)
      end
    end

    context "nil" do
      let(:inventory_number) { nil }
      it { expect(subject).to eql("") }
    end

    context "blank" do
      let(:inventory_number) { "" }
      it { expect(subject).to eql("") }
    end

    context "123456" do
      let(:inventory_number) { "123456" }
      it do
        expect(subject).to start_with("X")
        expect(subject.length).to eql(7)
      end
    end

  end

end

context "Inventory#anonymize_designation_name" do
  subject { Inventory.anonymize_designation_name(designation_name) }
  
  context 'anonymize_designation_name' do
    context "standard shipment" do
      let(:designation_name) { "S12345" }
      it do
        expect(subject).to start_with('S')
        expect(subject.length).to eql(6)
      end
    end

    context "GC-12345" do
      let(:designation_name) { "GC-12345" }
      it do
        expect(subject).to start_with('GC-')
        expect(subject.length).to eql(8)
        expect(subject.length).to_not eql("GC-123245")
      end
    end

    context "nil" do
      let(:designation_name) { nil }
      it { expect(subject).to eql("") }
    end

    context "blank" do
      let(:designation_name) { "" }
      it { expect(subject).to eql("") }
    end

    context "9" do
      let(:designation_name) { "9" }
      it do
        expect(subject).to start_with("GC-")
        expect(subject.size).to eql(8)
      end
    end

    context "Dec16Stocktake" do
      let(:designation_name) { "Dec16Stocktake" }
      it do
        expect(subject).to start_with("GC-")
        expect(subject.size).to eql(8)
      end
    end

    context "L123245" do
      let(:designation_name) { "L123245" }
      it do
        expect(subject).to start_with("L")
        expect(subject.size).to eql(6)
        expect(subject).to_not eql("L123245")
      end
    end

    context "C12345-Belgium" do
      let(:designation_name) { "C12345-Belgium" }
      it do
        expect(subject).to start_with("C")
        expect(subject.size).to eql(6)
        expect(subject).to_not eql("C12345-Belgium")
      end
    end

  end

end
