#!/usr/bin/env ruby

require 'rubygems'
require 'fileutils'
require 'rake'

PRODUCT         = "couchbase-sync-gateway"
PRODUCT_BASE    = "couchbase"
PRODUCT_KIND    = "sync-gateway"
DEBEMAIL        = "build@couchbase.com"

PREFIX          = ARGV[0] || "/opt/couchbase"
PREFIXD         = ARGV[1] || "./opt-couchbase-sync-gateway"
PRODUCT_VERSION = ARGV[2] || "1.0-1234"
RELEASE         = PRODUCT_VERSION.split('-')[0]

PKGNAME="#{PRODUCT}_#{PRODUCT_VERSION}"
product_base_cap = PRODUCT_BASE[0..0].upcase + PRODUCT_BASE[1..-1] # Ex: "Couchbase".

STARTDIR  = Dir.getwd()
STAGE_DIR = "#{STARTDIR}/build/deb/#{PKGNAME}"
FileUtils.rm_rf   "#{STAGE_DIR}"
FileUtils.mkdir_p "#{STAGE_DIR}/opt"
FileUtils.mkdir_p "#{STAGE_DIR}/etc"

sh %{cd #{STAGE_DIR} && dh_make -e #{DEBEMAIL} --native --single --packagename #{PKGNAME}}

FileUtils.copy_entry #{PREFIXD} #{STAGE_DIR}/opt/#{PRODUCT}

[["#{PRODUCT_KIND}", "#{STAGE_DIR}/debian"]].each do |src_dst|
[["#{STARTDIR}", "#{STAGE_DIR}/debian"]].each do |src_dst|
    Dir.chdir(src_dst[0]) do
        Dir.glob("*.tmpl").each do |x|
            target = "#{src_dst[1]}/#{x.gsub('.tmpl', '')}"
            sh %{sed -e s,@@VERSION@@,#{PRODUCT_VERSION},g #{x}         |
                 sed -e s,@@RELEASE@@,#{RELEASE},g                      |
                 sed -e s,@@PREFIX@@,#{PREFIX},g                        |
                 sed -e s,@@PRODUCT@@,#{PRODUCT},g                      |
                 sed -e s,@@PRODUCT_BASE@@,#{PRODUCT_BASE},g            |
                 sed -e s,@@PRODUCT_BASE_CAP@@,#{product_base_cap},g    |
                 sed -e s,@@PRODUCT_KIND@@,#{PRODUCT_KIND},g > #{target}}
            sh %{chmod a+x #{target}}
        end 
    end
end


Dir.chdir #{STAGE_DIR} do
  #sh %{dch -b -v #{PRODUCT_VERSION} "Released debian package for version #{PRODUCT_VERSION}"}
  sh %{dpkg-buildpackage -B -uc}
end
