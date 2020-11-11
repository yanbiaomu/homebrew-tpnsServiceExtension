# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class NewTpnsSvcExt < Formula
  desc "自动创建TPNSService通知扩展插件"
  homepage "https://github.com/yanbiaomu/tpns-service-extension.git"
  url "https://github.com/yanbiaomu/tpns-service-extension.git", :using => :git, :tag => '0.0.1'

  # 因为依赖了 `xcodeproj` 这个 gem，所以在 resource 中添加 `xcodeproj`
  resource "xcodeproj" do
    url "https://rubygems.org/downloads/xcodeproj-1.19.0.gem"
    sha256 "d6892fbd5750d5ca738923be5b19b2ec2dd2b1074e141e1de90c7cebb4912190"
  end

  def install

    # 创建 vendor 文件夹，用来放所有依赖的 gem
    (lib/"tpnsService/vendor").mkpath

    # 安装依赖的每一个 gem
    resources.each do |r|
      r.verify_download_integrity(r.fetch)
      system("gem", "install", r.cached_download, "--no-document",
             "--install-dir", "#{lib}/tpnsService/vendor")
    end

    # 安装所有源代码
    libexec.install Dir["*"]

    # 创建 new_tpns_svc_ext 命令
    bin.write_exec_script(libexec/"new_tpns_svc_ext")

    new_tpns_service_path = (bin/"new_tpns_svc_ext")

    # 修改 new_tpns_svc_ext 的权限，让它可以被更改
    FileUtils.chmod 0755, new_tpns_service_path

    # 把下面的脚本写入 new_tpns_svc_ext 命令中
    File.write(new_tpns_service_path, exec_script)

  end

  def exec_script
    <<~EOS
      #!/bin/bash
      export DISABLE_BUNDLER_SETUP=1
      # 在 path 中添加 vendor 目录，每次执行 new_tpns_svc_ext 的时候，就可以找到依赖了
      export GEM_HOME="#{HOMEBREW_PREFIX}/lib/tpnsService/vendor"

      # 拷贝 TPNSService 文件夹的内容到项目目录
      mkdir -p $3/../TPNSService
      cp -af #{libexec}/TPNSService/* $3/../TPNSService

      # 执行对 NotificationService.m 文件的修改
      #{libexec}/tpns_service_auto_code "$1" "$2" "$3/../TPNSService/NotificationService.m"
  
      # 执行我们创建的 new_tpns_svc_ext 文件
      exec ruby "#{libexec}/new_tpns_svc_ext" "$3"

    EOS
  end

end
