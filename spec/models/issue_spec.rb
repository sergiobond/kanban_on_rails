require 'rails_helper'

RSpec.describe Issue, :type => :model do
  let(:user) { create :user }

  let(:issue) { create :issue }

  let(:user_to_issue_connection) { create :user_to_issue_connection, :user => user, :issue => issue }

  describe '#sync_with_github' do
    context 'when new issue' do
      before do
        stub_request(:patch, 'https://api.github.com/repos/some/project/issues/').
          with(:body => '{"labels":[]}', :headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token token',
            'Content-Type' => 'application/json', 'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(:status => 200, :body => '', :headers => {})

        stub_request(:post, 'https://api.github.com/repos/some/project/issues').
          with(:body => '{"labels":[],"title":"Some title"}',
            :headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token token', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(:status => 200, :headers => {}, :body => '')

        user.authentications.create! :uid => 123, :provider => 'github', :token => 'token'
      end

      it { expect(user_to_issue_connection.issue.sync_with_github(user.id)).to eq true }
    end

    context 'when existing issue' do
      before do
        stub_request(:patch, 'https://api.github.com/repos/some/project/issues/').
          with(:body => '{"labels":[]}', :headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token token',
            'Content-Type' => 'application/json', 'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(:status => 200, :body => '', :headers => {})

        stub_request(:patch, 'https://api.github.com/repos/some/project/issues/1').
          with(:body => '{"title":"Some title","body":null,"labels":[],"state":"open"}',
            :headers => { 'Accept' => 'application/vnd.github.v3+json',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => 'token token', 'Content-Type' => 'application/json',
            'User-Agent' => 'Octokit Ruby Gem 4.3.0' }).
          to_return(:status => 200, :body => '', :headers => {})

        user.authentications.create! :uid => 123, :provider => 'github', :token => 'token'

        user_to_issue_connection.issue.update_attributes(:github_issue_number => 1)
      end

      it { expect(user_to_issue_connection.issue.sync_with_github(user.id)).to eq '' }
    end
  end

  describe '#sync_with_gitlab' do
    context 'when new issue' do
      before do
        stub_request(:post, 'https://gitlab.com/api/v3/projects//issues').
          with(:body => 'title=Some%20title&description=&labels=',
            :headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :headers => {}, :body => { :id => '1' }.to_json.to_s)

        user.authentications.create! :uid => 123, :provider => 'gitlab', :token => 'token',
          :gitlab_private_token => 'token'
      end

      it { expect(user_to_issue_connection.issue.sync_with_gitlab(user.id)).to eq true }
    end

    context 'when existing issue' do
      before do
        stub_request(:put, 'https://gitlab.com/api/v3/projects//issues/1').
          with(:body => 'title=Some%20title&description=&labels=',
            :headers => { 'Accept' => 'application/json', 'Private-Token' => 'token' }).
          to_return(:status => 200, :body => '', :headers => {})

        user.authentications.create! :uid => 123, :provider => 'gitlab', :token => 'token',
          :gitlab_private_token => 'token'

        user_to_issue_connection.issue.update_attributes(:gitlab_issue_id => 1)
      end

      it { expect(user_to_issue_connection.issue.sync_with_gitlab(user.id)).to eq false }
    end
  end

  describe '#sync_with_bitbucket' do
    context 'when new issue' do
      before do
        stub_request(:post, 'https://api.bitbucket.org/2.0/repositories/username/slug/issues/').
          with(:body => '{"title":"Some title"}',
            :headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => /.*/, 'Content-Type' => 'application/json',
            'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
          to_return(:status => 200, :body => {}.to_json.to_s, :headers => {})

        user.authentications.create! :uid => 123, :provider => 'bitbucket', :token => 'token'

        user_to_issue_connection.issue.project.update_attributes(:bitbucket_owner => 'username',
          :bitbucket_slug => 'slug')
      end

      it { expect(user_to_issue_connection.issue.sync_with_bitbucket(user.id)).to eq nil }
    end

    context 'when existing issue' do
      before do
        stub_request(:put, 'https://api.bitbucket.org/1.0/repositories/username/slug/issues/1/').
          with(:body => '{"title":"Some title","content":null}',
            :headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'Authorization' => /.*/, 'Content-Type' => 'application/json',
            'User-Agent' => 'BitBucket Ruby Gem 0.1.7' }).
          to_return(:status => 200, :body => {}.to_json.to_s, :headers => {})

        user.authentications.create! :uid => 123, :provider => 'bitbucket', :token => 'token'

        user_to_issue_connection.issue.project.update_attributes(:bitbucket_owner => 'username',
          :bitbucket_slug => 'slug')

        user_to_issue_connection.issue.update_attributes(:bitbucket_issue_id => 1)
      end

      it { expect(user_to_issue_connection.issue.sync_with_bitbucket(user.id).size).to eq 0 }
    end
  end

  describe '#save' do
    context 'without any backlog columns' do
      it { expect(issue.tap { |i| i.tags = ['new'] }.save).to eq true }
    end

    context 'with backlog column' do
      before do
        board = create :board, :projects => [issue.project]

        create :section, :include_all => true, :board => board

        create :column, :backlog => true, :board => board, :tags => []
      end

      it { expect(issue.tap { |i| i.tags = ['new'] }.save).to eq true }
    end
  end
end
