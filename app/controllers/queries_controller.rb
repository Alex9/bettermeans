# BetterMeans - Work 2.0
# Copyright (C) 2006-2011  See readme for details and license#

class QueriesController < ApplicationController
  menu_item :issues
  before_filter :find_query, :except => :new
  before_filter :find_optional_project, :only => :new

  def new
    @query = Query.new(params[:query])
    @query.project = params[:query_is_for_all] ? nil : @project
    @query.user = User.current
    @query.is_public = false unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
    @query.column_names = nil if params[:default_columns]

    params[:fields].each do |field|
      @query.add_filter(field, params[:operators][field], params[:values][field])
    end if params[:fields]
    @query.group_by ||= params[:group_by]

    if request.post? && params[:confirm] && @query.save
      flash.now[:success] = l(:notice_successful_create)
      redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :query_id => @query
      return
    end
    render :layout => false if request.xhr?
  end

  def edit
    if request.post?
      @query.filters = {}
      params[:fields].each do |field|
        @query.add_filter(field, params[:operators][field], params[:values][field])
      end if params[:fields]
      @query.attributes = params[:query]
      @query.project = nil if params[:query_is_for_all]
      @query.is_public = false unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      @query.column_names = nil if params[:default_columns]

      if @query.save
        flash.now[:success] = l(:notice_successful_update)
        redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :query_id => @query
      end
    end
  end

  def destroy
    @query.destroy if request.post?
    redirect_to :controller => 'issues', :action => 'index', :project_id => @project, :set_filter => 1
  end

  private

  def find_query
    @query = Query.find(params[:id])
    @project = @query.project
    render_403 unless @query.editable_by?(User.current)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id]
    User.current.allowed_to?(:save_queries, @project, :global => true)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
