%w(bson connection_pool optionable moped pg).each do |name|
  path = Dir.glob("#{ Gem.dir }/specifications/#{ name }-*.gemspec").first
  raise "Run bundle from #{ Rails.root.join('ouroboros') } first" unless File.exists?(path)
  Gem::Specification.load(path).activate
end

require 'moped'

mongo = Moped::Session.new ['127.0.0.1:27017']
mongo.use 'ouroboros'

zooniverse_user = User.find_by(login: 'the_zooniverse')
unless zooniverse_user
  zooniverse_user = User.new({
    login: 'the_zooniverse',
    display_name: 'The Zooniverse',
    email: 'panoptes@zooniverse.org',
    password: 'asdf123456789'
  })
  zooniverse_user.build_identity_group
  zooniverse_user.save!
end

# =================================
# = Migrate project and workflows =
# =================================
mongo_project = mongo[:projects].find(name: 'galaxy_zoo').first
project = Project.find_by_name mongo_project['name']

unless project
  p = Project.new({
    name: mongo_project['name'],
    display_name: mongo_project['display_name'],
    primary_language: 'en'
  })
  
  p.user_count = mongo_project['user_count']
  p.created_at = mongo_project['created_at']
  p.updated_at = mongo_project['updated_at']
  p.classifications_count = 0
  p.owner = zooniverse_user
  p.save!
  project = p
end

workflow = Workflow.find_by(display_name: 'galaxy_zoo_5') || Workflow.create({
  display_name: 'galaxy_zoo_5',
  tasks: [],
  project_id: project.id,
  grouped: true
})


# =================
# = Migrate users =
# =================
user_query = mongo[:users].find "projects.#{ mongo_project['_id'] }" => { :$exists => true }
total = user_query.count
index = 0
invalid = []
users = { }
user_query.each do |user|
  index += 1
  puts "Migrating users: #{ index } / #{ total }" if index % 500 == 0
  
  migrated_user = User.find_by(login: user['name'])
  unless migrated_user
    begin
      migrated_user = User.new({
        login: user['name'],
        display_name: user['name'],
        email: user['email'],
        password: 'asdf123456789'
      })
      migrated_user.build_identity_group
      
      migrated_user.save!
    rescue => e
      puts e.message
      migrated_user = nil
    end
  end
  
  users[user['_id']] = migrated_user
end


# ==================
# = Migrate groups =
# ==================
total = mongo[:galaxy_zoo_groups].find.count
index = 0
groups = { }

mongo[:galaxy_zoo_groups].find.each do |group|
  index += 1
  puts "Migrating groups: #{ index } / #{ total }"
  
  subject_set = SubjectSet.find_by(name: group['name'])
  
  unless subject_set
    subject_set = SubjectSet.create({
      display_name: group['name'],
      project_id: project.id
    })
    workflow.subject_sets << subject_set
  end
  
  groups[group['_id']] = subject_set
end


# ====================
# = Migrate subjects =
# ====================
total = mongo[:galaxy_zoo_subjects].find.count
index = 0
subjects = { }

mongo[:galaxy_zoo_subjects].find.each do |subject|
  index += 1
  puts "Migrating subjects: #{ index } / #{ total }"
  
  migrated_subject = Subject.find_by(zooniverse_id: subject['zooniverse_id'])
  
  unless migrated_subject
    migrated_subject = Subject.new
    migrated_subject.zooniverse_id = subject['zooniverse_id']
    migrated_subject.metadata = subject['metadata']
    migrated_subject.locations = subject['location']
    migrated_subject.created_at = subject['created_at']
    migrated_subject.updated_at = subject['updated_at']
    migrated_subject.owner = zooniverse_user
    migrated_subject.project = project
    migrated_subject.save!
    
    subject_set = groups[subject['group_id']]
    set_member_subject = SetMemberSubject.new
    set_member_subject.state = case subject['state']
    when 'active'
      'active'
    when 'complete'
      'retired'
    else
      'inactive'
    end
    
    set_member_subject.subject_set = subject_set
    set_member_subject.subject = migrated_subject
    set_member_subject.classifications_count = 0
    set_member_subject.save!
  end
  
  subjects[subject['_id']] = migrated_subject.set_member_subjects.first
end; nil


# ===========================
# = Migrate classifications =
# ===========================
total = mongo[:galaxy_zoo_classifications].find.count
index = 0

mongo[:galaxy_zoo_classifications].find.sort(created_at: 1).each do |classification|
  index += 1
  puts "Migrating classifications: #{ index } / #{ total }" if index % 1_000 == 0
  set_member_subject = subjects[classification['subject_ids'].first]
  unless set_member_subject
    puts 'no subject'
    next
  end
  user = users[classification['user_id']]
  
  migrated_classification = Classification.new
  migrated_classification.project = project
  migrated_classification.set_member_subject = set_member_subject
  migrated_classification.user = user
  migrated_classification.workflow = workflow
  migrated_classification.annotations = classification['annotations']
  migrated_classification.created_at = classification['created_at']
  migrated_classification.updated_at = classification['updated_at']
  migrated_classification.user_ip = classification['user_ip']
  migrated_classification.save!
  
  if user
    UserSeenSubject.add_seen_subject_for_user user_id: user.id, workflow_id: workflow.id, subject_id: set_member_subject.subject_id
  end
end; nil
