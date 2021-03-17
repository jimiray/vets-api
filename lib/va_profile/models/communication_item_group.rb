require_relative 'communication_item'

module VAProfile
  module Models
    class CommunicationItemGroup < Base
      attribute :name, String
      attribute :description, String

      attribute :communication_items, Array[VAProfile::Models::CommunicationItem], default: []

      def self.create_groups(res)
        groups = {}

        res['bios'].each do |communication_item|
          communication_item_group = communication_item['communication_item_groups'][0]
          communication_group_id = communication_item_group['communication_group_id']

          groups[communication_group_id] ||= new(
            name: communication_item_group['communication_group']['name'],
            description: communication_item_group['communication_group']['description']
          )

          groups[communication_group_id].communication_items << VAProfile::Models::CommunicationItem.new(
            id: communication_item['communication_item_id'],
            name: communication_item['common_name'],
            communication_channels: communication_item['communication_item_channels'].map do |communication_item_channel|
              communication_channel = communication_item_channel['communication_channel']

              VAProfile::Models::CommunicationChannel.new(
                id: communication_channel['communication_channel_id'],
                name: communication_channel['name'],
                description: communication_channel['description']
              )
            end
          )
        end

        groups.values
      end
    end
  end
end
