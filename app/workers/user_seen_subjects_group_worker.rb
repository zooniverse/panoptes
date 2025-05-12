class UserSeenSubjectsGroupWorker
    include Sidekiq::Worker

    sidekiq_options(
        retry: 5,
        batch_flush_size: 1000,
        batch_flush_interval: 3,
        queue: :data_high,
        lock: :until_executed
      )
     #[ [{user_id: , workflow_id:, subject_ids_arr:}]
     #  [{user_id: , workflow_id:, subject_ids_arr:}]
     #]
    def perform(group)
      puts 'MDY114 GROUP'
      merged_items = group.flatten.each_with_object({}) do |item, hash|
        puts 'MDY114 ITEM'
        puts item
        key = [item["user_id"], item["workflow_id"]]
        puts "MDY114 KEY"
        puts key
        hash[key] ||= { user_id: item["user_id"], workflow_id: item["workflow_id"], subject_ids_arr: [] }
        puts 'MDY114 HASH KEY '
        puts hash[key]
        hash[key][:subject_ids_arr] << item["subject_ids_arr"]
      end
      puts "MDY114 MERGED ITEMS"
      puts merged_items

      params_arr = merged_items.values
      puts "MDY114 PARAMS ARR"
      puts params_arr
      params_arr.each do |param|
        puts param[:user_id]
        puts param[:workflow_id]
        puts param[:subject_ids_arr].flatten.to_s
        # # {user_ud, worklow_id: , subject_ids_arr}
        UserSeenSubjectsWorker.perform_async(param[:user_id], param[:workflow_id], param[:subject_ids_arr].flatten)
      end
    end
end