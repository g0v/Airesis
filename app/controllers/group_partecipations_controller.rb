#encoding: utf-8
class GroupPartecipationsController < ApplicationController
  include NotificationHelper


  layout 'groups'

  #carica il gruppo
  before_filter :load_group

  before_filter :load_group_partecipation, :except => [:index, :send_email]

  #sicurezza
  before_filter :authenticate_user!


  def index
    @group_partecipations = @group.group_partecipations.search(params[:search])

    @partecipants = @group_partecipations
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data build_csv }
    end
  end

  def build_csv
    CSV.generate do |csv|
      csv << [t('pages.groups.participations.surname'), t('pages.groups.participations.name'), t('pages.groups.participations.role'), t('pag  es.groups.participations.member_since')]   #TODO:il18n
      @group_partecipations.each do |group_partecipation|
        csv << [group_partecipation.user.surname, group_partecipation.user.name, group_partecipation.partecipation_role.name, group_partecipation.created_at ? (l group_partecipation.created_at) : ' ']
      end
    end
  end


  #send a massive email to all users
  def send_email
    ids = params[:message][:receiver_ids]
    subject = params[:message][:subject]
    body = params[:message][:body]
    ResqueMailer.massive_email(current_user.id, ids, @group.id, subject, body).deliver!
    flash[:notice] = t('info.message_sent')
  end

  def destroy
    authorize! :destroy, @group_partecipation

    @group_partecipation_request = GroupPartecipationRequest.find_by_user_id_and_group_id(@group_partecipation.user_id, @group_partecipation.group_id)

    if (@group_partecipation.partecipation_role_id == PartecipationRole::PORTAVOCE) &&
        (@group_partecipation.group.portavoce.count == 1)
      flash[:error] = t('error.group_partecipations.destroy')
    else
      GroupPartecipation.transaction do
        @group_partecipation_request.destroy
        @group_partecipation.destroy
        AreaPartecipation.joins(:group_area => :group).where(['groups.id = ? AND area_partecipations.user_id = ?',@group_partecipation.group_id, @group_partecipation.user_id]).readonly(false).destroy_all
      end
      flash[:notice] = current_user == @group_partecipation.user ? t('info.group_partecipations.destroy_ok_1') : I18n.t('info.participation_roles.user_removed_from_group',name:@group_partecipation.user.fullname) #TODO:il18n
    end

    respond_to do |format|
      format.html { redirect_to :back }
      #format.xml  { head :ok }
    end
  end

  protected

  def load_group_partecipation
    @group_partecipation = GroupPartecipation.find(params[:id])
  end


end
