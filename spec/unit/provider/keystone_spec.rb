require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone'
require 'tempfile'


klass = Puppet::Provider::Keystone

class Puppet::Provider::Keystone
  def self.reset
    @admin_endpoint = nil
    @tenant_hash    = nil
    @admin_token    = nil
    @keystone_file  = nil
  end
end

describe Puppet::Provider::Keystone do

  after :each do
    klass.reset
  end


  describe 'when retrieving the security token' do

    it 'should return nothing if there is no keystone config file' do
      ini_file = Puppet::Util::IniConfig::File.new
      t = Tempfile.new('foo')
      path = t.path
      t.unlink
      ini_file.read(path)
      expect(klass.get_admin_token).to be_nil
    end

    it 'should return nothing if the keystone config file does not have a DEFAULT section' do
      mock = {}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_token).to be_nil
    end

    it 'should fail if the keystone config file does not contain an admin token' do
      mock = {'DEFAULT' => {'not_a_token' => 'foo'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      expect(klass.get_admin_token).to be_nil
    end

    it 'should parse the admin token if it is in the config file' do
      mock = {'DEFAULT' => {'admin_token' => 'foo'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_token.should == 'foo'
    end

    it 'should use the specified bind_host in the admin endpoint' do
      mock = {'DEFAULT' => {'admin_bind_host' => '192.168.56.210', 'admin_port' => '35357' }}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://192.168.56.210:35357/v2.0/'
    end

    it 'should use localhost in the admin endpoint if bind_host is 0.0.0.0' do
      mock = {'DEFAULT' => { 'admin_bind_host' => '0.0.0.0', 'admin_port' => '35357' }}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://127.0.0.1:35357/v2.0/'
    end

    it 'should use localhost in the admin endpoint if bind_host is unspecified' do
      mock = {'DEFAULT' => { 'admin_port' => '35357' }}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://127.0.0.1:35357/v2.0/'
    end

    it 'should use https if ssl is enabled' do
      mock = {'DEFAULT' => {'admin_bind_host' => '192.168.56.210', 'admin_port' => '35357' }, 'ssl' => {'enable' => 'True'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'https://192.168.56.210:35357/v2.0/'
    end

    it 'should use http if ssl is disabled' do
      mock = {'DEFAULT' => {'admin_bind_host' => '192.168.56.210', 'admin_port' => '35357' }, 'ssl' => {'enable' => 'False'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'http://192.168.56.210:35357/v2.0/'
    end

    it 'should use the defined admin_endpoint if available' do
      mock = {'DEFAULT' => {'admin_endpoint' => 'https://keystone.example.com' }, 'ssl' => {'enable' => 'False'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'https://keystone.example.com/v2.0/'
    end

    it 'should handle an admin_endpoint with a trailing slash' do
      mock = {'DEFAULT' => {'admin_endpoint' => 'https://keystone.example.com/' }, 'ssl' => {'enable' => 'False'}}
      Puppet::Util::IniConfig::File.expects(:new).returns(mock)
      mock.expects(:read).with('/etc/keystone/keystone.conf')
      klass.get_admin_endpoint.should == 'https://keystone.example.com/v2.0/'
    end

  end

end
