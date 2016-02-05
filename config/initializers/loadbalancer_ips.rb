aws_ips_file_path = Rails.root.join("config/aws_ips.json")

# File should always exist in prod/stag but allow testing this in dev mode if file exists
if Rails.env.production? or Rails.env.staging? or File.exists?(aws_ips_file_path)
  json = File.read(aws_ips_file_path)
  data = JSON.load(json)

  proxy_ips = data.fetch("prefixes")
                  .select { |i| i.fetch("service") == "CLOUDFRONT" }
                  .map { |i| IPAddr.new(i.fetch("ip_prefix")) }

  Rails.application.config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + proxy_ips
end
