class Group < ActiveRecord::Base
  include ImageHelper
  REQ_BY_PORTAVOCE = 'p'
  REQ_BY_VOTE = 'v'
  REQ_BY_BOTH = 'b'

  validates_presence_of :name
  validates_length_of :name, :within => 3..60
  validates_uniqueness_of :name

  validates_presence_of :description
  validates_length_of :image_url, :within => 1..255, :allow_blank => true
  validates_length_of :facebook_page_url, :within => 10..255, :allow_blank => true
  validates_length_of :title_bar, :within => 1..255, :allow_blank => true
  validates_presence_of :interest_border_id
  validates_presence_of :default_role_name, :on => :create

  #has_many :meeting_organizations, :class_name => 'MeetingsOrganization'
  attr_accessible :partecipant_tokens, :name, :description, :accept_requests, :facebook_page_url, :group_partecipations, :interest_border_tkn, :title_bar, :image_url, :default_role_name, :default_role_actions, :image, :admin_title, :private, :rule_book, :tags_list
  attr_reader :partecipant_tokens
  attr_accessor :default_role_name, :default_role_actions, :current_user_id


  has_many :group_partecipations, :class_name => 'GroupPartecipation', :dependent => :destroy, :order => 'id DESC'
  has_many :group_follows, :class_name => 'GroupFollow', :dependent => :destroy
  has_many :post_publishings, :class_name => 'PostPublishing', :dependent => :destroy
  has_many :partecipants, :through => :group_partecipations, :source => :user, :class_name => 'User'
  has_many :followers, :through => :group_follows, :source => :user, :class_name => 'User'
  has_many :posts, :through => :post_publishings, :source => :blog_post, :class_name => 'BlogPost'
  has_many :partecipation_requests, :class_name => 'GroupPartecipationRequest', :dependent => :destroy
  has_many :partecipation_roles, :class_name => 'PartecipationRole', :dependent => :destroy, :order => 'id DESC'
  #has_many :partecipation_roles, :class_name => 'PartecipationRole'
  belongs_to :interest_border, :class_name => 'InterestBorder', :foreign_key => :interest_border_id
  belongs_to :default_role, :class_name => 'PartecipationRole', :foreign_key => :partecipation_role_id
  has_many :meeting_organizations, :class_name => 'MeetingOrganization', :foreign_key => 'group_id', :dependent => :destroy

  has_many :events, :through => :meeting_organizations, :class_name => 'Event', :source => :event

  has_many :proposal_supports, :class_name => 'ProposalSupport', :dependent => :destroy
  has_many :proposals, :through => :proposal_supports, :class_name => 'Proposal'
  # belongs_to :image, :class_name => 'Image', :foreign_key => :image_id

  has_many :action_abilitations, :class_name => 'ActionAbilitation'


  has_many :group_elections, :class_name => 'GroupElection'
  #elezioni a cui partecipa
  has_many :elections, :through => :group_elections, :class_name => 'Election'

  has_many :supporters, :class_name => 'Supporter'
  #candidati che sostiene alle elezioni
  has_many :candidates, :through => :supporters, :class_name => 'Candidate'

  has_many :group_proposals, :class_name => 'GroupProposal', :dependent => :destroy
  has_many :internal_proposals, :through => :group_proposals, :class_name => 'Proposal', :source => :proposal

  has_many :group_quorums, :class_name => 'GroupQuorum', :dependent => :destroy
  has_many :quorums, :through => :group_quorums, :class_name => 'Quorum', :source => :quorum, order: 'seq nulls last, quorums.id'


  has_many :voters, :through => :group_partecipations, :source => :user, :class_name => 'User', :include => [:partecipation_roles], :conditions => ["partecipation_roles.id = ?", 2]

  has_many :invitation_emails, :class_name => 'GroupInvitationEmail', dependent: :destroy

  has_many :group_areas, dependent: :destroy

  has_many :group_affinities, dependent: :destroy


  has_many :search_partecipants

  has_many :group_tags, :dependent => :destroy
  has_many :tags, :through => :group_tags, :class_name => 'Tag'

  # Check for paperclip
  has_attached_file :image,
                    :styles => {
                        :thumb => "100x100#",
                        :medium => "300x300>",
                        :small => "150x150>"
                    },
                    :url => "/assets/images/groups/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/assets/images/groups/:id/:style/:basename.:extension"

  validates_attachment_size :image, :less_than => 2.megabytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  before_create :pre_populate
  after_create :after_populate

  before_save :normalize_blank_values
  before_save :save_tags, :if => :not_resaving?

  def tags_list
    @tags_list ||= self.tags.map(&:text).join(', ')
  end

  def tags_list_json
    @tags_list ||= self.tags.map(&:text).join(', ')
  end

  def tags_list=(tags_list)
    @tags_list = tags_list
  end

  def tags_with_links
    html = self.tags.collect { |t| "<a href=\"/tags/#{t.text.strip}\">#{t.text.strip}</a>" }.join(', ')
    return html
  end

  def save_tags
    if @tags_list
      tids = []
      @tags_list.split(/,/).each do |tag|
        stripped = tag.strip.downcase.gsub('.', '')
        t = Tag.find_or_create_by_text(stripped)
        tids << t.id
      end
      self.tag_ids = tids
    end
  end

  def not_resaving?
    !@resaving
  end


  def normalize_blank_values
    [:admin_title].each do |att|
      self[att] = nil if self[att].blank?
    end
  end

  def pre_populate
    self.default_visible_outside = true

    #fai si che chi crea il gruppo ne sia anche portavoce
    self.partecipation_requests.build({:user_id => current_user_id, :group_partecipation_request_status_id => 3})

    self.group_partecipations.build({:user_id => current_user_id, :partecipation_role_id => 2}) #portavoce

    Quorum.public.each do |quorum|
      copy = quorum.dup
      copy.public = false
      copy.save!
      self.group_quorums.build(:quorum_id => copy.id)
    end
    role = self.partecipation_roles.build({name: self.default_role_name, description: I18n.t('pages.groups.edit_permissions.default_role')})
    self.default_role_actions.each do |action_id|
      abilitation = role.action_abilitations.build(group_action_id: action_id)
      abilitation.save!
    end
    role.save!
    self.partecipation_role_id = role.id

  end

  def after_populate
    self.default_role.update_attribute(:group_id, self.id)
    ids = self.default_role.action_abilitations.pluck(:id)
    ActionAbilitation.update_all({:group_id => self.id}, {:id => ids})
  end

  def destroy
    self.update_attribute(:partecipation_role_id, 2) && super
  end

  #return true if the group is private and do not show anything to non-partecipants
  def is_private?
    self.private
  end

  #utenti che possono votare
  def count_voter_partecipants
    self.partecipants.count(
        :joins => "join partecipation_roles
               on group_partecipations.partecipation_role_id = partecipation_roles.id
               left join action_abilitations on partecipation_roles.id = action_abilitations.partecipation_role_id",
        :conditions => "(action_abilitations.group_action_id = 7 AND action_abilitations.group_id = #{self.id}) or (partecipation_roles.id = 2)")
  end

  #utenti che possono eseguire un'azione
  def scoped_partecipants(action_id)
    self.partecipants.all(
        :joins => "join partecipation_roles
               on group_partecipations.partecipation_role_id = partecipation_roles.id
               left join action_abilitations on partecipation_roles.id = action_abilitations.partecipation_role_id",
        :conditions => ["(action_abilitations.group_action_id = ? AND action_abilitations.group_id = ?) or (partecipation_roles.id = ?)", action_id, self.id, PartecipationRole::PORTAVOCE])
  end

  #restituisce la lista dei portavoce del gruppo
  def portavoce
    return self.partecipants.where(:conditions => {"group_partecipations.partecipation_role_id" => 2})
  end

  def partecipant_tokens=(ids)
    self.partecipant_ids = ids.split(",")
  end


  def image_url
    if self.image.exists?
      return self.image.url
    elsif read_attribute(:image_url) != nil
      return read_attribute(:image_url)
    else
      return ""
    end
  end


  def interest_border_tkn
    return self.interest_border.territory_type + "-" + self.interest_border.territory_id.to_s if self.interest_border
  end

  def interest_border_tkn=(tkn)
    unless tkn.blank?
      ftype = tkn[0, 1] #tipologia (primo carattere)
      fid = tkn[2..-1] #chiave primaria (dal terzo all'ultimo carattere)
      found = InterestBorder.table_element(tkn)
      if found #se ho trovato qualcosa, allora l'identificativo è corretto e posso procedere alla creazione del confine di interesse
        interest_b = InterestBorder.find_or_create_by_territory_type_and_territory_id(InterestBorder::I_TYPE_MAP[ftype], fid)
        puts "New Record!" if (interest_b.new_record?)
        self.interest_border = interest_b
      end
    end
  end

  def request_by_vote?
    return true if self.accept_requests == REQ_BY_VOTE
    return false
  end

  def request_by_portavoce?
    return true if self.accept_requests == REQ_BY_PORTAVOCE
    return false
  end

  def request_by_both?
    return true if self.accept_requests == REQ_BY_BOTH
    return false
  end

  def self.look(params)
    search = params[:search]
    tag = params[:tag]

    page = params[:page] || 1

    #retrieve all possible interest borders
    if params[:interest_border_obj]
      if params[:area]
        @interest_borders = params[:interest_border_obj].id
      else
        @interest_borders = []
        @interest_borders << params[:interest_border_obj].id
        if params[:interest_border_obj].territory_type == InterestBorder::CONTINENTE
          statos = params[:interest_border_obj].territory.statos
          stato_ids = InterestBorder.where({territory_id: statos.pluck(:id), territory_type: 'Stato'}).pluck(:id)
          @interest_borders += stato_ids
          regiones = Regione.where(:stato_id => statos.pluck(:id))
          @interest_borders += pluck_regiones(regiones)
        elsif params[:interest_border_obj].territory_type == InterestBorder::STATO
          regiones = params[:interest_border_obj].territory.regiones
          @interest_borders += pluck_regiones(regiones)
        elsif params[:interest_border_obj].territory_type == InterestBorder::REGIONE
          provincias = params[:interest_border_obj].territory.provincias
          @interest_borders += pluck_provincias(provincias)
        elsif params[:interest_border_obj].territory_type == InterestBorder::PROVINCIA
          comunes = params[:interest_border_obj].territory.comunes
          @interest_borders += pluck_comunes(comunes)
        end

      end
      params[:interest_border_ids] = @interest_borders
    end

    if search.to_s != '' then
      Group.search do
        fulltext search
        with(:interest_border_id, params[:interest_border_ids]) if params[:interest_border_obj]
        order_by :group_partecipations_count, :desc
        order_by :created_at, :desc
      end.results
    elsif params[:interest_border_obj]
      Group.all(:conditions => {:interest_border_id => @interest_borders}, :order => 'group_partecipations_count desc, created_at desc', limit: 30)
    elsif tag then
      Group.all(:joins => :tags, :conditions => ['tags.text = ?', tag], :order => 'group_partecipations_count desc, created_at desc', limit: 30)
    else
      #Group.paginate(:page => page, :per_page => 15, :order => 'group_partecipations_count desc, created_at desc')
      []
    end
  end

  def to_param
    "#{id}-#{name.downcase.gsub(/[^a-zA-Z0-9]+/, '-').gsub(/-{2,}/, '-').gsub(/^-|-$/, '')}"
  end

  searchable do
    text :name, boost: 5
    text :description
    integer :interest_border_id
    integer :group_partecipations_count
    time :created_at
  end


  private

  def self.pluck_regiones(regiones)
    interest_borders = []
    regione_ids = InterestBorder.where({territory_id: regiones.pluck(:id), territory_type: 'Regione'}).pluck(:id)
    interest_borders += regione_ids
    provincias = Provincia.where(:regione_id => regiones.pluck(:id))
    interest_borders += pluck_provincias(provincias)
  end

  def self.pluck_provincias(provincias)
    interest_borders = []
    provincia_ids = InterestBorder.where({territory_id: provincias.pluck(:id), territory_type: 'Provincia'}).pluck(:id)
    interest_borders += provincia_ids

    comunes = Comune.where(:provincia_id => provincias.pluck(:id))
    interest_borders += pluck_comunes(comunes)
  end

  def self.pluck_comunes(comunes)
    interest_borders = []
    comune_ids = InterestBorder.where({territory_id: comunes.pluck(:id), territory_type: 'Comune'}).pluck(:id)
    interest_borders += comune_ids
  end
end
