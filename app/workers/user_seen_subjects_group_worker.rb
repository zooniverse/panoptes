class UserSeenSubjectsGroupWorker
    include Sidekiq::Worker

    sidekiq_options(
      retry: 5,
      batch_flush_size: 1000,
      batch_flush_interval: 3,
      queue: :data_high,
      lock: :until_executed
    )

    def perform(grouped_args)
      merged_items = grouped_args.flatten.each_with_object({}) do |item, hash|
        key = [item["user_id"], item["workflow_id"]]
        hash[key] ||= { user_id: item["user_id"], workflow_id: item["workflow_id"], subject_ids_arr: [] }
        hash[key][:subject_ids_arr] << item["subject_ids_arr"]
      end

      params_arr = merged_items.values
      params_arr.each do |param|
         # {user_id:, worklow_id: , subject_ids_arr}
        UserSeenSubjectsWorker.perform_async(param[:user_id], param[:workflow_id], param[:subject_ids_arr].flatten)
      end
    end
end