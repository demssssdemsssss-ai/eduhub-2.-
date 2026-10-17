import React, { useEffect, useMemo, useState } from 'react'
import {
  Activity, ArrowRight, Bell, BookOpen, CheckCircle2, ChevronDown, CircleHelp,
  ClipboardList, Copy, GraduationCap, HeartHandshake, Home, LogOut, Menu,
  MessageCircle, Plus, Search, Settings, ShieldCheck, Sparkles, Target, Users,
  X, ChartNoAxesCombined, CalendarDays, Award, LockKeyhole, ExternalLink
} from 'lucide-react'
import { supabase, isSupabaseConfigured } from './supabase'

const statusMeta = {
  Mastered: { color: 'green', dot: '🟢' },
  Developing: { color: 'yellow', dot: '🟡' },
  'Needs Support': { color: 'red', dot: '🔴' },
  'Not Started': { color: 'gray', dot: '⚪' }
}

function initials(name='EduHub User') {
  return name.split(' ').filter(Boolean).slice(0,2).map(x => x[0]).join('').toUpperCase()
}
function makeCode(prefix='ENG7') {
  return `${prefix}-${Math.random().toString(36).slice(2,7).toUpperCase()}`
}
function App() {
  const [session, setSession] = useState(null)
  const [profile, setProfile] = useState(null)
  const [page, setPage] = useState('Overview')
  const [roleChoice, setRoleChoice] = useState('student')
  const [authMode, setAuthMode] = useState('login')
  const [showAuth, setShowAuth] = useState(false)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [classes, setClasses] = useState([])
  const [announcements, setAnnouncements] = useState([])
  const [grades, setGrades] = useState([])
  const [lessons, setLessons] = useState([])
  const [activities, setActivities] = useState([])
  const [searchTerm, setSearchTerm] = useState('')
  const [mobileMenu, setMobileMenu] = useState(false)
  const [showCreateClass, setShowCreateClass] = useState(false)
  const [showCreateLesson, setShowCreateLesson] = useState(false)
  const [showCreateActivity, setShowCreateActivity] = useState(false)
  const [showJoin, setShowJoin] = useState(false)
  const [showLinkChild, setShowLinkChild] = useState(false)
  const [showAnnouncement, setShowAnnouncement] = useState(false)
  const [selectedLesson, setSelectedLesson] = useState(null)
  const [quizAnswer, setQuizAnswer] = useState('')
  const [quizResult, setQuizResult] = useState(null)
  const [linkedChildren, setLinkedChildren] = useState([])
  const [messages, setMessages] = useState([])
  const [notifications, setNotifications] = useState([])

  const [auth, setAuth] = useState({ name:'', email:'', password:'', confirm:'', role:'student', studentId:'', teacherId:'', classCode:'', subject:'', school:'', childId:'', linkCode:'' })
  const [classForm, setClassForm] = useState({ name:'', subject:'', section:'' })
  const [lessonForm, setLessonForm] = useState({ title:'', subject:'', description:'', content:'', class_id:'' })
  const [activityForm, setActivityForm] = useState({ title:'', subject:'', question:'', correct_answer:'', points:10, class_id:'' })
  const [joinCode, setJoinCode] = useState('')
  const [parentForm, setParentForm] = useState({ childId:'', linkCode:'' })
  const [announcementForm, setAnnouncementForm] = useState({ title:'', body:'', class_id:'' })
  const [messageForm, setMessageForm] = useState({ recipient:'', body:'' })

  const role = profile?.role || 'student'
  const displayName = profile?.full_name || session?.user?.user_metadata?.full_name || session?.user?.email?.split('@')[0] || 'Learner'
  const isTeacher = role === 'teacher'
  const isParent = role === 'parent'
  const isStudent = role === 'student'

  useEffect(() => {
    if (!isSupabaseConfigured) { setLoading(false); return }
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session)
      if (data.session) loadProfile(data.session.user.id)
      else setLoading(false)
    })
    const { data: listener } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next)
      if (next) { setLoading(true); setTimeout(() => loadProfile(next.user.id), 0) }
      else { setProfile(null); setClasses([]); setLoading(false) }
    })
    return () => listener.subscription.unsubscribe()
  }, [])

  async function loadProfile(userId) {
    try {
      const { data, error } = await supabase.from('profiles').select('*').eq('id', userId).maybeSingle()
      if (error) throw error
      setProfile(data)
      if (data) await loadWorkspace(data)
    } catch (e) { setError(e.message || 'Could not load your profile.') }
    finally { setLoading(false) }
  }

  async function loadWorkspace(p=profile) {
    if (!p || !supabase) return
    try {
      let classRows = []
      if (p.role === 'teacher') {
        const { data, error } = await supabase.from('classes').select('*').eq('teacher_id', p.id).eq('archived', false).order('created_at', { ascending:false })
        if (error) throw error
        classRows = data || []
      } else if (p.role === 'student') {
        const { data: links, error: linkErr } = await supabase.from('class_members').select('class_id, classes(*)').eq('student_id', p.id)
        if (linkErr) throw linkErr
        classRows = (links || []).map(x => x.classes).filter(Boolean)
      } else {
        const { data: links, error: linkErr } = await supabase.from('parent_student_links').select('student_id, profiles:student_id(id, full_name, student_id)').eq('parent_id', p.id).eq('status','active')
        if (linkErr) throw linkErr
        setLinkedChildren((links || []).map(x => x.profiles).filter(Boolean))
      }
      setClasses(classRows)
      const classIds = classRows.map(c => c.id)
      if (classIds.length) {
        const [{ data: lessonData }, { data: activityData }, { data: announcementData }] = await Promise.all([
          supabase.from('lessons').select('*').in('class_id', classIds).eq('published', true).order('created_at', { ascending:false }),
          supabase.from('activities').select('*').in('class_id', classIds).eq('published', true).order('created_at', { ascending:false }),
          supabase.from('announcements').select('*').in('class_id', classIds).order('created_at', { ascending:false })
        ])
        setLessons(lessonData || [])
        setActivities(activityData || [])
        setAnnouncements(announcementData || [])
      } else {
        setLessons([]); setActivities([]); setAnnouncements([])
      }
      const { data: gradeData } = await supabase.from('grades').select('*').eq('student_id', p.id).order('created_at', { ascending:false })
      setGrades(gradeData || [])
      const { data: notificationData } = await supabase.from('notifications').select('*').eq('user_id', p.id).order('created_at', { ascending:false }).limit(10)
      setNotifications(notificationData || [])
    } catch (e) { setError(e.message || 'Some dashboard data could not be loaded.') }
  }

  function updateAuth(k,v) { setAuth(old => ({ ...old, [k]:v })) }
  function updateForm(setter,k,v) { setter(old => ({ ...old, [k]:v })) }

  async function handleAuth(e) {
    e.preventDefault(); setError(''); setNotice('')
    if (!isSupabaseConfigured) { setError('Connect Supabase first. Follow the SETUP.md instructions included with this project.'); return }
    if (authMode === 'register' && auth.password !== auth.confirm) { setError('Passwords do not match.'); return }
    setBusy(true)
    try {
      if (authMode === 'register') {
        if (auth.role === 'student' && !auth.classCode.trim()) throw new Error('A class code is required for student registration.')
        if (auth.role === 'parent' && (!auth.childId.trim() || !auth.linkCode.trim())) throw new Error('Child Student ID and Parent Link Code are required.')
        const { data, error: signErr } = await supabase.auth.signUp({
          email: auth.email.trim(),
          password: auth.password,
          options: { emailRedirectTo: window.location.origin, data: { full_name: auth.name.trim(), role: auth.role } }
        })
        if (signErr) throw signErr
        if (data.user) {
          const { error: profileErr } = await supabase.from('profiles').insert({
            id: data.user.id, full_name: auth.name.trim(), email: auth.email.trim(), role: auth.role,
            student_id: auth.role === 'student' ? auth.studentId.trim() : null,
            teacher_id: auth.role === 'teacher' ? auth.teacherId.trim() : null,
            subject_department: auth.role === 'teacher' ? auth.subject.trim() : null,
            school: auth.role === 'teacher' ? auth.school.trim() : null
          })
          if (profileErr) throw profileErr
          if (auth.role === 'student') {
            const { data: cls, error: codeErr } = await supabase.from('classes').select('id,name,teacher_id,class_code,archived').eq('class_code', auth.classCode.trim().toUpperCase()).eq('archived', false).maybeSingle()
            if (codeErr) throw codeErr
            if (!cls) throw new Error('Invalid or expired class code. Please ask your teacher for the correct code.')
            const { error: memberErr } = await supabase.from('class_members').insert({ class_id: cls.id, student_id: data.user.id })
            if (memberErr) throw memberErr
          }
          if (auth.role === 'parent') {
            const { data: child, error: childErr } = await supabase.from('profiles').select('id,student_id,full_name').eq('student_id', auth.childId.trim()).eq('role','student').maybeSingle()
            if (childErr) throw childErr
            if (!child) throw new Error('Student ID was not found.')
            const { data: code, error: codeErr } = await supabase.from('parent_link_codes').select('*').eq('student_id', child.id).eq('code', auth.linkCode.trim().toUpperCase()).eq('used', false).maybeSingle()
            if (codeErr) throw codeErr
            if (!code || new Date(code.expires_at) < new Date()) throw new Error('Invalid or expired parent link code.')
            const { error: linkErr } = await supabase.from('parent_student_links').insert({ parent_id:data.user.id, student_id:child.id, status:'active' })
            if (linkErr) throw linkErr
            await supabase.from('parent_link_codes').update({ used:true }).eq('id',code.id)
          }
        }
        setNotice('Account created. Check your email to verify your account if email confirmation is enabled.')
        setShowAuth(false)
        if (data.session) { setSession(data.session); await loadProfile(data.user.id) }
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email:auth.email.trim(), password:auth.password })
        if (error) throw error
        setShowAuth(false)
      }
    } catch (e) { setError(e.message || 'Authentication failed.') }
    finally { setBusy(false) }
  }

  async function logout() {
    if (supabase) await supabase.auth.signOut()
    setSession(null); setProfile(null); setPage('Overview')
  }

  async function createClass(e) {
    e.preventDefault(); setError(''); setNotice('')
    if (!classForm.name.trim()) return setError('Enter a class name.')
    setBusy(true)
    try {
      const code = makeCode((classForm.subject || classForm.name).replace(/[^A-Z0-9]/gi,'').slice(0,4).toUpperCase() || 'CLASS')
      const { error } = await supabase.from('classes').insert({
        teacher_id:profile.id, name:classForm.name.trim(), subject:classForm.subject.trim(),
        section:classForm.section.trim(), class_code:code
      })
      if (error) throw error
      setShowCreateClass(false); setClassForm({ name:'',subject:'',section:'' })
      setNotice(`Class created. Class code: ${code}`); await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not create class.') }
    finally { setBusy(false) }
  }

  async function joinClass(e) {
    e.preventDefault(); setError(''); setNotice('')
    try {
      const { data: cls, error } = await supabase.from('classes').select('*').eq('class_code',joinCode.trim().toUpperCase()).eq('archived',false).maybeSingle()
      if (error) throw error
      if (!cls) throw new Error('Invalid or expired class code. Please ask your teacher for the correct code.')
      const { error: joinErr } = await supabase.from('class_members').insert({ class_id:cls.id, student_id:profile.id })
      if (joinErr) throw joinErr
      setShowJoin(false); setJoinCode(''); setNotice(`You have successfully joined ${cls.name}.`); await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not join class.') }
  }

  async function copyCode(code) {
    try { await navigator.clipboard.writeText(code); setNotice(`Copied class code: ${code}`) }
    catch { setNotice(`Class code: ${code} — select and copy it manually.`) }
  }

  async function regenerateCode(cls) {
    const next = makeCode((cls.subject || cls.name).replace(/[^A-Z0-9]/gi,'').slice(0,4).toUpperCase() || 'CLASS')
    const { error } = await supabase.from('classes').update({ class_code:next }).eq('id',cls.id)
    if (error) setError(error.message)
    else { setNotice(`New code generated: ${next}`); await loadWorkspace() }
  }

  async function archiveClass(cls) {
    if (!confirm(`Archive ${cls.name}? Students will no longer be able to join with its code.`)) return
    const { error } = await supabase.from('classes').update({ archived:true }).eq('id',cls.id)
    if (error) setError(error.message); else { setNotice('Class archived.'); await loadWorkspace() }
  }

  async function createLesson(e) {
    e.preventDefault(); setError('')
    try {
      const { error } = await supabase.from('lessons').insert({
        teacher_id:profile.id, class_id:lessonForm.class_id, title:lessonForm.title.trim(),
        subject:lessonForm.subject.trim(), description:lessonForm.description.trim(),
        content:lessonForm.content.trim(), published:true
      })
      if (error) throw error
      setShowCreateLesson(false); setLessonForm({ title:'',subject:'',description:'',content:'',class_id:'' })
      setNotice('Lesson published to the selected class.'); await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not publish lesson.') }
  }

  async function createActivity(e) {
    e.preventDefault(); setError('')
    try {
      const { error } = await supabase.from('activities').insert({
        teacher_id:profile.id, class_id:activityForm.class_id, title:activityForm.title.trim(),
        subject:activityForm.subject.trim(), question:activityForm.question.trim(),
        correct_answer:activityForm.correct_answer.trim(), points:Number(activityForm.points) || 10, published:true
      })
      if (error) throw error
      setShowCreateActivity(false); setActivityForm({ title:'',subject:'',question:'',correct_answer:'',points:10,class_id:'' })
      setNotice('Activity published.'); await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not create activity.') }
  }

  async function submitQuiz(activity) {
    if (!quizAnswer.trim()) return setError('Please enter your answer.')
    try {
      const correct = quizAnswer.trim().toLowerCase() === activity.correct_answer.trim().toLowerCase()
      const score = correct ? Number(activity.points) : 0
      const { error: attemptErr } = await supabase.from('quiz_attempts').insert({ activity_id:activity.id, student_id:profile.id, answer:quizAnswer.trim(), score, max_score:Number(activity.points), submitted_at:new Date().toISOString() })
      if (attemptErr) throw attemptErr
      const { error: gradeErr } = await supabase.from('grades').insert({ student_id:profile.id, class_id:activity.class_id, activity_id:activity.id, title:activity.title, score, max_score:Number(activity.points), subject:activity.subject })
      if (gradeErr) throw gradeErr
      setQuizResult({ score, max:Number(activity.points), correct }); setQuizAnswer('')
      setNotice('Your answer was submitted and your score was saved.')
      await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not submit the quiz.') }
  }

  async function createAnnouncement(e) {
    e.preventDefault()
    try {
      const { error } = await supabase.from('announcements').insert({ teacher_id:profile.id, class_id:announcementForm.class_id, title:announcementForm.title.trim(), body:announcementForm.body.trim() })
      if (error) throw error
      setShowAnnouncement(false); setAnnouncementForm({title:'',body:'',class_id:''}); setNotice('Announcement posted.'); await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not post announcement.') }
  }

  async function linkChild(e) {
    e.preventDefault()
    try {
      const { data: child, error: childErr } = await supabase.from('profiles').select('id,student_id,full_name').eq('student_id',parentForm.childId.trim()).eq('role','student').maybeSingle()
      if (childErr) throw childErr
      if (!child) throw new Error('Student ID was not found.')
      const { data: code, error: codeErr } = await supabase.from('parent_link_codes').select('*').eq('student_id',child.id).eq('code',parentForm.linkCode.trim().toUpperCase()).eq('used',false).maybeSingle()
      if (codeErr) throw codeErr
      if (!code || new Date(code.expires_at) < new Date()) throw new Error('Invalid or expired parent link code.')
      const { error } = await supabase.from('parent_student_links').insert({ parent_id:profile.id, student_id:child.id, status:'active' })
      if (error) throw error
      await supabase.from('parent_link_codes').update({used:true}).eq('id',code.id)
      setShowLinkChild(false); setParentForm({childId:'',linkCode:''}); setNotice(`${child.full_name} has been successfully linked to your parent account.`); await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not link child.') }
  }

  async function generateParentCode() {
    const code = `PARENT-${Math.random().toString(36).slice(2,8).toUpperCase()}`
    const { error } = await supabase.from('parent_link_codes').insert({ student_id:profile.id, code, expires_at:new Date(Date.now()+7*86400000).toISOString() })
    if (error) setError(error.message)
    else setNotice(`Share this code privately with your authorized parent/guardian: ${code}. It expires in 7 days.`)
  }

  async function sendMessage(e) {
    e.preventDefault()
    try {
      const { error } = await supabase.from('messages').insert({ sender_id:profile.id, recipient_id:messageForm.recipient.trim(), body:messageForm.body.trim() })
      if (error) throw error
      setMessageForm({recipient:'',body:''}); setNotice('Message sent.'); await loadWorkspace()
    } catch (e) { setError(e.message || 'Could not send message. Recipient must be a valid user ID with permitted access.') }
  }

  const filteredClasses = useMemo(() => classes.filter(c => `${c.name} ${c.subject||''} ${c.section||''}`.toLowerCase().includes(searchTerm.toLowerCase())), [classes,searchTerm])
  const average = grades.length ? Math.round(grades.reduce((a,g) => a + (Number(g.max_score) ? Number(g.score)/Number(g.max_score)*100 : 0),0)/grades.length) : 0
  const mastered = average >= 85 ? 1 : 0
  const developing = average >= 60 && average < 85 ? 1 : 0
  const needsSupport = grades.length && average < 60 ? 1 : 0

  if (loading) return <div className="loading-screen"><div className="brand-mark"><Activity/></div><h2>EduHub 2.0</h2><p>Loading your learning space…</p></div>

  if (!session || !profile) {
    return <Landing
      configured={isSupabaseConfigured}
      showAuth={showAuth} setShowAuth={setShowAuth}
      authMode={authMode} setAuthMode={setAuthMode}
      auth={auth} updateAuth={updateAuth} handleAuth={handleAuth}
      roleChoice={roleChoice} setRoleChoice={setRoleChoice}
      busy={busy} error={error} notice={notice} setError={setError}
    />
  }

  const nav = isTeacher
    ? [{label:'Overview',icon:Home},{label:'My Classes',icon:Users},{label:'Lessons',icon:BookOpen},{label:'Activities & Quizzes',icon:ClipboardList},{label:'Learning Pulse',icon:Activity},{label:'Announcements',icon:Bell},{label:'Messages',icon:MessageCircle}]
    : isParent
    ? [{label:'Overview',icon:Home},{label:'My Child',icon:HeartHandshake},{label:'Learning Pulse',icon:Activity},{label:'Grades',icon:ChartNoAxesCombined},{label:'Announcements',icon:Bell},{label:'Messages',icon:MessageCircle}]
    : [{label:'Overview',icon:Home},{label:'My Subjects',icon:BookOpen},{label:'Lessons',icon:BookOpen},{label:'Activities & Quizzes',icon:ClipboardList},{label:'Learning Pulse',icon:Activity},{label:'Announcements',icon:Bell},{label:'Messages',icon:MessageCircle}]

  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileMenu?'sidebar-open':''}`}>
        <div className="brand"><div className="brand-mark"><Activity size={22}/></div><div><strong>EduHub <span>2.0</span></strong><small>The Learning Pulse</small></div><button className="icon-btn mobile-close" onClick={()=>setMobileMenu(false)}><X/></button></div>
        <div className="workspace-label">WORKSPACE</div>
        <nav>{nav.map(item => <button key={item.label} className={`nav-item ${page===item.label?'active':''}`} onClick={()=>{setPage(item.label);setMobileMenu(false)}}><item.icon size={18}/><span>{item.label}</span>{item.label==='Messages'&&messages.length>0&&<i/>}</button>)}</nav>
        <div className="sidebar-bottom"><div className="help-card"><div className="help-icon"><CircleHelp size={18}/></div><strong>Need a hand?</strong><p>Learning is better together.</p><button onClick={()=>setNotice('Ask your teacher for help through Messages.')}>Get support <ArrowRight size={14}/></button></div><div className="user-mini"><div className="avatar">{initials(displayName)}</div><div className="user-mini-text"><strong>{displayName}</strong><small>{role}</small></div><button className="icon-btn" onClick={logout} title="Sign out"><LogOut size={17}/></button></div></div>
      </aside>
      {mobileMenu && <div className="scrim" onClick={()=>setMobileMenu(false)}/>}
      <main className="main-area">
        <header className="topbar"><button className="icon-btn mobile-menu-btn" onClick={()=>setMobileMenu(true)}><Menu/></button><div className="breadcrumb">Workspace <span>/</span> <b>{page}</b></div><div className="topbar-actions"><div className="search-box"><Search size={16}/><input value={searchTerm} onChange={e=>setSearchTerm(e.target.value)} placeholder="Search your workspace"/></div><button className="icon-btn notification-btn" onClick={()=>setPage('Announcements')}><Bell size={19}/>{notifications.length>0&&<i/>}</button><div className="avatar top-avatar">{initials(displayName)}</div></div></header>
        <div className="content">
          {error && <div className="alert alert-error"><span>{error}</span><button onClick={()=>setError('')}><X size={16}/></button></div>}
          {notice && <div className="alert alert-success"><CheckCircle2 size={17}/><span>{notice}</span><button onClick={()=>setNotice('')}><X size={16}/></button></div>}
          <div className="welcome-row"><div><div className="eyebrow"><Sparkles size={14}/> YOUR LEARNING SPACE</div><h1>{greeting()}, {displayName.split(' ')[0]}! <span className="wave">✦</span></h1><p>{isTeacher?'Here is what is happening across your classes today.':isParent?'A clear view of your child’s progress, all in one place.':'Small steps make meaningful progress. Let’s keep going.'}</p></div>{isTeacher&&<button className="primary-btn" onClick={()=>setShowCreateClass(true)}><Plus size={17}/> Create class</button>}{isStudent&&<button className="primary-btn" onClick={()=>setShowJoin(true)}><Plus size={17}/> Join another class</button>}{isParent&&<button className="primary-btn" onClick={()=>setShowLinkChild(true)}><Plus size={17}/> Link a child</button>}</div>
          {page==='Overview' && <Overview role={role} classes={classes} lessons={lessons} activities={activities} grades={grades} average={average} mastered={mastered} developing={developing} needsSupport={needsSupport} announcements={announcements} linkedChildren={linkedChildren} onPage={setPage} onJoin={()=>setShowJoin(true)} onCreateLesson={()=>setShowCreateLesson(true)} onCreateActivity={()=>setShowCreateActivity(true)} onAnnouncement={()=>setShowAnnouncement(true)} onOpenLesson={setSelectedLesson}/>}
          {page==='My Classes' && <Classes classes={filteredClasses} isTeacher={isTeacher} onCreate={()=>setShowCreateClass(true)} onCopy={copyCode} onRegenerate={regenerateCode} onArchive={archiveClass}/>}
          {page==='My Subjects' && <Classes classes={filteredClasses} isTeacher={false} onCreate={()=>setShowJoin(true)} onCopy={copyCode}/>}
          {page==='Lessons' && <Lessons lessons={lessons} isTeacher={isTeacher} onCreate={()=>setShowCreateLesson(true)} onOpen={setSelectedLesson}/>}
          {page==='Activities & Quizzes' && <Activities activities={activities} grades={grades} isTeacher={isTeacher} onCreate={()=>setShowCreateActivity(true)} onOpen={setSelectedLesson}/>}
          {page==='Learning Pulse' && <Pulse grades={grades} average={average} mastered={mastered} developing={developing} needsSupport={needsSupport} isTeacher={isTeacher} classes={classes}/>}
          {page==='Grades' && <Grades grades={grades} average={average}/>}
          {page==='My Child' && <ParentChild childrenList={linkedChildren} onLink={()=>setShowLinkChild(true)}/>}
          {page==='Announcements' && <Announcements announcements={announcements} isTeacher={isTeacher} onCreate={()=>setShowAnnouncement(true)}/>}
          {page==='Messages' && <Messages messages={messages} profile={profile} form={messageForm} setForm={setMessageForm} onSend={sendMessage}/>}
          {page!=='Overview' && !['My Classes','My Subjects','Lessons','Activities & Quizzes','Learning Pulse','Grades','My Child','Announcements','Messages'].includes(page) && <div className="panel"><h2>{page}</h2><p>This area is ready to be expanded with your connected EduHub data.</p></div>}
        </div>
        <footer className="footer"><span>© 2026 EduHub 2.0</span><span>See Learning. Understand Progress. Improve Together.</span><span><ShieldCheck size={14}/> Learning with care</span></footer>
      </main>
      {showAuth && <Modal title={authMode==='register'?'Create your account':'Welcome back'} onClose={()=>setShowAuth(false)}><AuthForm auth={auth} updateAuth={updateAuth} authMode={authMode} setAuthMode={setAuthMode} onSubmit={handleAuth} busy={busy} error={error} setError={setError}/></Modal>}
      {showCreateClass && <Modal title="Create a class" onClose={()=>setShowCreateClass(false)}><form className="form-stack" onSubmit={createClass}><Field label="Class name" value={classForm.name} onChange={v=>updateForm(setClassForm,'name',v)} placeholder="English 7 — Section A" required/><Field label="Subject" value={classForm.subject} onChange={v=>updateForm(setClassForm,'subject',v)} placeholder="English" required/><Field label="Section" value={classForm.section} onChange={v=>updateForm(setClassForm,'section',v)} placeholder="Section A"/><button className="primary-btn full" disabled={busy}><Plus size={17}/> Create class & generate code</button></form></Modal>}
      {showCreateLesson && <Modal title="Publish a lesson" onClose={()=>setShowCreateLesson(false)}><form className="form-stack" onSubmit={createLesson}><Field label="Lesson title" value={lessonForm.title} onChange={v=>updateForm(setLessonForm,'title',v)} placeholder="Understanding Proper Nouns" required/><Field label="Subject" value={lessonForm.subject} onChange={v=>updateForm(setLessonForm,'subject',v)} placeholder="English" required/><SelectField label="Class" value={lessonForm.class_id} onChange={v=>updateForm(setLessonForm,'class_id',v)} options={classes.map(c=>({value:c.id,label:c.name}))} required/><Field label="Short description" value={lessonForm.description} onChange={v=>updateForm(setLessonForm,'description',v)} placeholder="What will students learn?"/><TextField label="Lesson content" value={lessonForm.content} onChange={v=>updateForm(setLessonForm,'content',v)} placeholder="Write lesson notes or paste a lesson link…" required/><button className="primary-btn full"><BookOpen size={17}/> Publish lesson</button></form></Modal>}
      {showCreateActivity && <Modal title="Create an activity" onClose={()=>setShowCreateActivity(false)}><form className="form-stack" onSubmit={createActivity}><Field label="Activity title" value={activityForm.title} onChange={v=>updateForm(setActivityForm,'title',v)} placeholder="Proper Nouns Quick Check" required/><Field label="Subject" value={activityForm.subject} onChange={v=>updateForm(setActivityForm,'subject',v)} placeholder="English" required/><SelectField label="Class" value={activityForm.class_id} onChange={v=>updateForm(setActivityForm,'class_id',v)} options={classes.map(c=>({value:c.id,label:c.name}))} required/><TextField label="Question" value={activityForm.question} onChange={v=>updateForm(setActivityForm,'question',v)} placeholder="Example: Which word is a proper noun?" required/><Field label="Correct answer (short answer)" value={activityForm.correct_answer} onChange={v=>updateForm(setActivityForm,'correct_answer',v)} placeholder="Example: Manila" required/><Field label="Points" value={activityForm.points} onChange={v=>updateForm(setActivityForm,'points',v)} type="number" required/><p className="form-hint">Starter version: one short-answer question, exact answer matching. Multiple-choice quizzes can be added next.</p><button className="primary-btn full"><ClipboardList size={17}/> Publish activity</button></form></Modal>}
      {showJoin && <Modal title="Join another class" onClose={()=>setShowJoin(false)}><form className="form-stack" onSubmit={joinClass}><p className="muted">Enter the class code provided by your teacher.</p><Field label="Class code" value={joinCode} onChange={setJoinCode} placeholder="ENG7-A8K29" required/><button className="primary-btn full"><ArrowRight size={17}/> Join class</button></form></Modal>}
      {showLinkChild && <Modal title="Link a child" onClose={()=>setShowLinkChild(false)}><form className="form-stack" onSubmit={linkChild}><p className="muted">Use the Student ID and one-time link code provided securely by the student or school.</p><Field label="Child's Student ID" value={parentForm.childId} onChange={v=>updateForm(setParentForm,'childId',v)} placeholder="2026-00125" required/><Field label="Parent link code" value={parentForm.linkCode} onChange={v=>updateForm(setParentForm,'linkCode',v)} placeholder="PARENT-JD4921" required/><button className="primary-btn full"><HeartHandshake size={17}/> Verify and link child</button></form></Modal>}
      {showAnnouncement && <Modal title="Post an announcement" onClose={()=>setShowAnnouncement(false)}><form className="form-stack" onSubmit={createAnnouncement}><Field label="Title" value={announcementForm.title} onChange={v=>updateForm(setAnnouncementForm,'title',v)} placeholder="Quiz reminder" required/><SelectField label="Class" value={announcementForm.class_id} onChange={v=>updateForm(setAnnouncementForm,'class_id',v)} options={classes.map(c=>({value:c.id,label:c.name}))} required/><TextField label="Announcement" value={announcementForm.body} onChange={v=>updateForm(setAnnouncementForm,'body',v)} placeholder="Write the class update…" required/><button className="primary-btn full"><Bell size={17}/> Publish announcement</button></form></Modal>}
      {selectedLesson && <Modal title={selectedLesson.title} onClose={()=>{setSelectedLesson(null);setQuizResult(null)}}><div className="lesson-reader"><div className="lesson-badge"><BookOpen size={20}/></div><p className="eyebrow">{selectedLesson.subject || 'Learning material'}</p><p>{selectedLesson.description}</p><div className="lesson-content">{selectedLesson.content || selectedLesson.question || 'Your teacher has not added lesson content yet.'}</div>{selectedLesson.correct_answer!==undefined&&isStudent&&<form className="form-stack" onSubmit={e=>{e.preventDefault();submitQuiz(selectedLesson)}}><Field label="Your answer" value={quizAnswer} onChange={setQuizAnswer} placeholder="Type your answer…" required/><button className="primary-btn full">Submit answer</button>{quizResult&&<div className={`quiz-result ${quizResult.correct?'right':'wrong'}`}>{quizResult.correct?'Correct!':'Not quite yet.'} Score: {quizResult.score}/{quizResult.max}</div>}</form>}</div></Modal>}
    </div>
  )
}

function greeting() {
  const h = new Date().getHours()
  return h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening'
}

function Landing({ configured, showAuth, setShowAuth, authMode, setAuthMode, auth, updateAuth, handleAuth, roleChoice, setRoleChoice, busy, error, notice, setError }) {
  return <div className="landing">
    <nav className="landing-nav"><div className="brand"><div className="brand-mark"><Activity size={22}/></div><div><strong>EduHub <span>2.0</span></strong><small>The Learning Pulse</small></div></div><div className="landing-nav-actions"><button className="text-btn" onClick={()=>{setAuthMode('login');setShowAuth(true)}}>Log in</button><button className="primary-btn" onClick={()=>{setAuthMode('register');setShowAuth(true)}}>Get started <ArrowRight size={16}/></button></div></nav>
    <section className="hero"><div className="hero-copy"><div className="hero-pill"><span className="pulse-dot"/> THE LEARNING PULSE <Sparkles size={14}/></div><h1>Learning is a journey.<br/><span>See every step.</span></h1><p className="hero-sub">One connected space for teachers, students, and families to understand progress and improve together.</p><div className="hero-actions"><button className="primary-btn large" onClick={()=>{setAuthMode('register');setShowAuth(true)}}>Create your account <ArrowRight size={18}/></button><button className="secondary-btn large" onClick={()=>{setAuthMode('login');setShowAuth(true)}}>I already have an account</button></div><div className="hero-trust"><ShieldCheck size={16}/> Learning progress with privacy at its heart</div></div><div className="hero-visual"><div className="orbit orbit-one"/><div className="orbit orbit-two"/><div className="pulse-card main-pulse-card"><div className="pulse-card-top"><div><span className="eyebrow">YOUR LEARNING PULSE</span><h3>Progress at a glance</h3></div><div className="spark-icon"><Activity size={19}/></div></div><div className="progress-ring-wrap"><svg viewBox="0 0 150 150" className="progress-ring"><circle cx="75" cy="75" r="60" fill="none" stroke="#efedf9" strokeWidth="12"/><circle cx="75" cy="75" r="60" fill="none" stroke="#6e61d9" strokeWidth="12" strokeLinecap="round" strokeDasharray="377" strokeDashoffset="90" transform="rotate(-90 75 75)"/></svg><div className="ring-center"><strong>76%</strong><span>overall progress</span></div></div><div className="status-list"><div><span className="status-dot green-dot"/>Mastered <b>7</b></div><div><span className="status-dot yellow-dot"/>Developing <b>3</b></div><div><span className="status-dot red-dot"/>Needs support <b>1</b></div></div></div><div className="floating-card float-top"><div className="float-icon green-bg"><CheckCircle2 size={17}/></div><div><strong>Great progress!</strong><small>Practice paid off</small></div><span>↗</span></div><div className="floating-card float-bottom"><div className="float-icon purple-bg"><GraduationCap size={18}/></div><div><strong>Everyone connected</strong><small>Teacher · Student · Parent</small></div></div></div></section>
    <section className="roles-section"><div className="section-heading"><span className="eyebrow">ONE PLATFORM, THREE PERSPECTIVES</span><h2>Everyone has a role in learning.</h2><p>Tools designed around what each person needs most.</p></div><div className="role-cards"><RoleCard icon={<GraduationCap/>} tone="purple" title="For Teachers" desc="Manage classes, assess learning, spot gaps, and guide every student forward." items={['Class & lesson management','Learning gap insights','Targeted interventions']} onClick={()=>{setRoleChoice('teacher');updateAuth('role','teacher');setAuthMode('register');setShowAuth(true)}}/><RoleCard icon={<BookOpen/>} tone="blue" title="For Students" desc="Explore lessons, complete activities, and understand your next learning step." items={['Lessons and quizzes','Personal progress pulse','Achievements & feedback']} onClick={()=>{setRoleChoice('student');updateAuth('role','student');setAuthMode('register');setShowAuth(true)}}/><RoleCard icon={<HeartHandshake/>} tone="peach" title="For Parents" desc="Follow your child’s progress and stay connected with their teachers." items={['Simple progress overview','Grades & activity updates','Teacher communication']} onClick={()=>{setRoleChoice('parent');updateAuth('role','parent');setAuthMode('register');setShowAuth(true)}}/></div></section>
    <section className="landing-bottom"><div><div className="brand-mark"><Activity size={20}/></div><h2>Progress is better when we see it together.</h2><p>Build understanding, one learning step at a time.</p></div><button className="primary-btn large" onClick={()=>{setAuthMode('register');setShowAuth(true)}}>Join EduHub <ArrowRight size={17}/></button></section>
    <footer className="landing-footer"><span>© 2026 EduHub 2.0</span><span>See Learning. Understand Progress. Improve Together.</span></footer>
    {(!configured || error || notice) && <div className="setup-notice">{!configured&&<p><b>Setup needed:</b> connect your Supabase project using the included SETUP.md before real registration and login can work.</p>}{error&&<p className="error-text">{error}<button onClick={()=>setError('')}>Dismiss</button></p>}{notice&&<p>{notice}</p>}</div>}
    {showAuth&&<Modal title={authMode==='register'?'Create your EduHub account':'Welcome back'} onClose={()=>setShowAuth(false)}><AuthForm auth={auth} updateAuth={updateAuth} authMode={authMode} setAuthMode={setAuthMode} onSubmit={handleAuth} busy={busy} error={error} setError={setError}/></Modal>}
  </div>
}

function RoleCard({icon,tone,title,desc,items,onClick}) {
  return <button className="role-card" onClick={onClick}><div className={`role-icon ${tone}`}>{icon}</div><h3>{title}</h3><p>{desc}</p><ul>{items.map(x=><li key={x}><CheckCircle2 size={15}/>{x}</li>)}</ul><span className="role-link">Get started <ArrowRight size={15}/></span></button>
}

function AuthForm({auth,updateAuth,authMode,setAuthMode,onSubmit,busy,error,setError}) {
  const [showPassword,setShowPassword]=useState(false)
  const [role,setRole]=useState(auth.role||'student')
  function changeRole(v){setRole(v);updateAuth('role',v)}
  return <form className="form-stack" onSubmit={onSubmit}>
    {authMode==='register'&&<><div className="role-select"><button type="button" className={role==='teacher'?'selected':''} onClick={()=>changeRole('teacher')}><GraduationCap size={18}/>Teacher</button><button type="button" className={role==='student'?'selected':''} onClick={()=>changeRole('student')}><BookOpen size={18}/>Student</button><button type="button" className={role==='parent'?'selected':''} onClick={()=>changeRole('parent')}><HeartHandshake size={18}/>Parent</button></div><Field label="Full name" value={auth.name} onChange={v=>updateAuth('name',v)} placeholder="Your full name" required/>{role==='student'&&<Field label="Student ID number" value={auth.studentId} onChange={v=>updateAuth('studentId',v)} placeholder="2026-00125" required/>}{role==='teacher'&&<><Field label="Teacher ID" value={auth.teacherId} onChange={v=>updateAuth('teacherId',v)} placeholder="TCH-001" required/><Field label="Subject / department" value={auth.subject} onChange={v=>updateAuth('subject',v)} placeholder="English Department" required/><Field label="School / institution" value={auth.school} onChange={v=>updateAuth('school',v)} placeholder="Your school" required/></>}{role==='student'&&<Field label="Class code" value={auth.classCode} onChange={v=>updateAuth('classCode',v.toUpperCase())} placeholder="ENG7-A8K29" required/>}{role==='parent'&&<><Field label="Child's Student ID" value={auth.childId} onChange={v=>updateAuth('childId',v)} placeholder="2026-00125" required/><Field label="Parent-child link code" value={auth.linkCode} onChange={v=>updateAuth('linkCode',v.toUpperCase())} placeholder="Provided securely by school/student" required/></>}</>}
    <Field label="Gmail / email address" value={auth.email} onChange={v=>updateAuth('email',v)} type="email" placeholder="you@gmail.com" required/>
    <Field label="Password" value={auth.password} onChange={v=>updateAuth('password',v)} type={showPassword?'text':'password'} placeholder="At least 8 characters" required/>
    {authMode==='register'&&<Field label="Confirm password" value={auth.confirm} onChange={v=>updateAuth('confirm',v)} type={showPassword?'text':'password'} placeholder="Enter password again" required/>}
    <label className="check-row"><input type="checkbox" checked={showPassword} onChange={e=>setShowPassword(e.target.checked)}/> Show password</label>
    {error&&<div className="form-error">{error}</div>}
    <button className="primary-btn full" disabled={busy}>{busy?'Please wait…':authMode==='register'?'Create account':'Log in'} <ArrowRight size={17}/></button>
    {authMode==='login'&&<button type="button" className="text-btn centered" onClick={async()=>{if(!auth.email)return setError('Enter your email address first.');const {error}=await (await import('./supabase')).supabase.auth.resetPasswordForEmail(auth.email,{redirectTo:window.location.origin});if(error)setError(error.message);else setError('Password reset email sent. Check your inbox.')}}>Forgot password?</button>}
    <p className="auth-switch">{authMode==='register'?'Already have an account?':'Don’t have an account?'} <button type="button" onClick={()=>{setError('');setAuthMode(authMode==='register'?'login':'register')}}>{authMode==='register'?'Log in':'Create account'}</button></p>
    <p className="privacy-note"><LockKeyhole size={13}/> Your educational information should only be visible to authorized users.</p>
  </form>
}

function Field({label,value,onChange,placeholder,type='text',required=false}) {
  return <label className="field"><span>{label}{required&&<i> *</i>}</span><input type={type} value={value??''} onChange={e=>onChange(e.target.value)} placeholder={placeholder} required={required} minLength={type==='password'?8:undefined}/></label>
}
function TextField({label,value,onChange,placeholder,required=false}) {
  return <label className="field"><span>{label}{required&&<i> *</i>}</span><textarea value={value??''} onChange={e=>onChange(e.target.value)} placeholder={placeholder} required={required} rows="4"/></label>
}
function SelectField({label,value,onChange,options,required=false}) {
  return <label className="field"><span>{label}{required&&<i> *</i>}</span><select value={value} onChange={e=>onChange(e.target.value)} required={required}><option value="">Select a class</option>{options.map(o=><option key={o.value} value={o.value}>{o.label}</option>)}</select></label>
}

function Overview({role,classes,lessons,activities,grades,average,mastered,developing,needsSupport,announcements,linkedChildren,onPage,onJoin,onCreateLesson,onCreateActivity,onAnnouncement,onOpenLesson}) {
  const teacher=role==='teacher', parent=role==='parent', student=role==='student'
  return <>
    <div className="stat-grid">
      <Stat icon={<BookOpen/>} label={teacher?'Active classes':parent?'Linked children':'My subjects'} value={parent?linkedChildren.length:classes.length} tone="purple" foot={teacher?'Your teaching spaces':parent?'Authorized connections':'Classes you are enrolled in'}/>
      <Stat icon={<ClipboardList/>} label={teacher?'Published lessons':parent?'Learning activities':'Available lessons'} value={teacher?lessons.length:parent?grades.length:lessons.length} tone="blue" foot={teacher?'Ready for students':parent?'Recorded results':'Keep learning at your pace'}/>
      <Stat icon={<ChartNoAxesCombined/>} label={teacher?'Activities & quizzes':parent?'Current average':'Activities to explore'} value={teacher?activities.length:parent?(grades.length?`${average}%`:'—'):activities.length} tone="peach" foot={parent?'Based on saved quiz scores':teacher?'Published assessments':'Practice builds confidence'}/>
      <Stat icon={<Award/>} label={teacher?'Announcements':parent?'Notifications':'Learning progress'} value={teacher?announcements.length:parent?'Updates':(grades.length?`${average}%`:'—')} tone="mint" foot={teacher?'Class updates':parent?'Stay informed':'Your progress snapshot'}/>
    </div>
    <div className="dashboard-grid">
      <section className="panel main-panel"><div className="panel-heading"><div><span className="eyebrow">{teacher?'YOUR CLASSROOMS':parent?'YOUR FAMILY':'KEEP MOVING FORWARD'}</span><h2>{teacher?'Your classes':parent?'Linked children':'Continue learning'}</h2></div><button className="subtle-btn" onClick={()=>onPage(teacher?'My Classes':parent?'My Child':'My Subjects')}>View all <ArrowRight size={15}/></button></div>
        {teacher ? classes.length ? <div className="class-list">{classes.slice(0,4).map(c=><div className="class-row" key={c.id}><div className="class-avatar purple">{initials(c.name)}</div><div className="class-info"><strong>{c.name}</strong><small>{c.subject||'Subject'} {c.section?`· ${c.section}`:''}</small></div><div className="class-code">{c.class_code}</div><button className="icon-btn" title="Copy class code" onClick={()=>navigator.clipboard?.writeText(c.class_code)}><Copy size={16}/></button></div>)}</div> : <Empty icon={<Users/>} title="No classes yet" text="Create your first class and invite students with a class code." action="Create a class" onClick={()=>onPage('My Classes')}/> :
        parent ? linkedChildren.length ? linkedChildren.map(c=><div className="child-row" key={c.id}><div className="avatar large-avatar">{initials(c.full_name)}</div><div><strong>{c.full_name}</strong><small>Student ID: {c.student_id||'—'}</small></div><span className="tag">Linked</span></div>) : <Empty icon={<HeartHandshake/>} title="No linked child yet" text="Link your child with their Student ID and secure link code." action="Link a child" onClick={()=>onPage('My Child')}/> :
        lessons.length ? <div className="lesson-list">{lessons.slice(0,4).map(l=><button className="lesson-row" key={l.id} onClick={()=>onOpenLesson(l)}><div className="lesson-icon"><BookOpen size={18}/></div><div><strong>{l.title}</strong><small>{l.subject||'Lesson'} · Open lesson</small></div><ArrowRight size={16}/></button>)}</div> : <Empty icon={<BookOpen/>} title="Your learning journey starts here" text="Join a class with the code your teacher shared, then your lessons will appear here." action="Join a class" onClick={onJoin}/>}
      </section>
      <section className="panel pulse-summary"><div className="panel-heading"><div><span className="eyebrow">THE LEARNING PULSE</span><h2>{parent?'Your child’s progress':'Progress snapshot'}</h2></div><div className="spark-icon"><Activity size={18}/></div></div><div className="pulse-score"><div className="score-number">{grades.length?`${average}%`:'—'}</div><div><strong>{grades.length?(average>=85?'Looking strong':average>=60?'Growing steadily':'Let’s practice together'):'Ready to begin'}</strong><p>{grades.length?'Based on saved quiz results':'Progress appears as results are recorded.'}</p></div></div><div className="mini-progress"><div className="mini-progress-head"><span>Recorded results</span><b>{grades.length}</b></div><div className="progress-track"><div className="progress-fill" style={{width:`${Math.min(average,100)}%`}}/></div></div><div className="status-counts"><div><span className="status-dot green-dot"/><span>Mastered</span><b>{mastered}</b></div><div><span className="status-dot yellow-dot"/><span>Developing</span><b>{developing}</b></div><div><span className="status-dot red-dot"/><span>Needs support</span><b>{needsSupport}</b></div></div><button className="subtle-btn full-subtle" onClick={()=>onPage('Learning Pulse')}>Explore Learning Pulse <ArrowRight size={15}/></button></section>
    </div>
    <div className="bottom-grid"><section className="panel"><div className="panel-heading"><div><span className="eyebrow">STAY IN THE LOOP</span><h2>Recent announcements</h2></div><button className="icon-btn" onClick={()=>onPage('Announcements')}><ArrowRight size={17}/></button></div>{announcements.length?announcements.slice(0,3).map(a=><div className="announcement-row" key={a.id}><div className="announcement-icon"><Bell size={17}/></div><div><strong>{a.title}</strong><p>{a.body}</p><small>{new Date(a.created_at).toLocaleDateString()}</small></div></div>):<Empty icon={<Bell/>} title="No announcements yet" text="Class updates will appear here." action={teacher?'Post an announcement':undefined} onClick={onAnnouncement}/>}</section>
      <section className="panel quick-actions"><div className="panel-heading"><div><span className="eyebrow">QUICK ACCESS</span><h2>What would you like to do?</h2></div></div>{teacher?<><QuickAction icon={<BookOpen/>} title="Publish a lesson" text="Share learning material with your class" onClick={onCreateLesson}/><QuickAction icon={<ClipboardList/>} title="Create an activity" text="Check understanding with a quick quiz" onClick={onCreateActivity}/><QuickAction icon={<Bell/>} title="Post an announcement" text="Keep students informed" onClick={onAnnouncement}/></>:<><QuickAction icon={<BookOpen/>} title="Browse lessons" text="Open your learning materials" onClick={()=>onPage('Lessons')}/><QuickAction icon={<ClipboardList/>} title="Practice an activity" text="Build your skills one step at a time" onClick={()=>onPage('Activities & Quizzes')}/><QuickAction icon={<MessageCircle/>} title="Ask for help" text="Connect with your teacher" onClick={()=>onPage('Messages')}/></>}</section></div>
  </>
}
function Stat({icon,label,value,tone,foot}) { return <div className="stat-card"><div className={`stat-icon ${tone}`}>{icon}</div><span className="stat-label">{label}</span><strong className="stat-value">{value}</strong><small>{foot}</small></div> }
function Empty({icon,title,text,action,onClick}) { return <div className="empty-state"><div className="empty-icon">{icon}</div><strong>{title}</strong><p>{text}</p>{action&&<button className="subtle-btn" onClick={onClick}>{action} <ArrowRight size={15}/></button>}</div> }
function QuickAction({icon,title,text,onClick}) { return <button className="quick-action" onClick={onClick}><div className="quick-icon">{icon}</div><div><strong>{title}</strong><small>{text}</small></div><ArrowRight size={16}/></button> }

function Classes({classes,isTeacher,onCreate,onCopy,onRegenerate,onArchive}) {
  return <div className="panel"><div className="panel-heading"><div><span className="eyebrow">{isTeacher?'CLASS MANAGEMENT':'YOUR LEARNING SPACES'}</span><h2>{isTeacher?'Manage your classes':'My subjects'}</h2><p>{isTeacher?'Create a class and share its unique code with students.':'Your enrolled classes and their details.'}</p></div><button className="primary-btn" onClick={onCreate}><Plus size={17}/>{isTeacher?'Create class':'Join class'}</button></div>{classes.length?<div className="classes-grid">{classes.map(c=><div className="class-card" key={c.id}><div className="class-card-top"><div className="class-avatar purple"><BookOpen size={19}/></div><span className="tag">{c.subject||'Class'}</span></div><h3>{c.name}</h3><p>{c.section||'Learning space'} {c.teacher_name?`· ${c.teacher_name}`:''}</p>{isTeacher&&<div className="code-block"><div><small>CLASS CODE</small><strong>{c.class_code}</strong></div><button className="icon-btn" onClick={()=>onCopy(c.class_code)} title="Copy code"><Copy size={16}/></button></div>}<div className="class-card-actions">{isTeacher&&<><button className="subtle-btn" onClick={()=>onRegenerate(c)}>Regenerate code</button><button className="icon-btn" onClick={()=>onArchive(c)} title="Archive class"><X size={16}/></button></>}{!isTeacher&&<span className="muted">You're enrolled</span>}</div></div>)}</div>:<Empty icon={<Users/>} title={isTeacher?'Your first class starts here':'No classes yet'} text={isTeacher?'Create a class, then share the code with your students.':'Ask your teacher for a class code to join your first subject.'} action={isTeacher?'Create a class':'Join a class'} onClick={onCreate}/>}</div>
}
function Lessons({lessons,isTeacher,onCreate,onOpen}) {
  return <div className="panel"><div className="panel-heading"><div><span className="eyebrow">LEARNING MATERIALS</span><h2>{isTeacher?'Lessons you’ve shared':'Your lessons'}</h2><p>{isTeacher?'Publish clear, helpful resources for your students.':'Open a lesson and learn at your own pace.'}</p></div>{isTeacher&&<button className="primary-btn" onClick={onCreate}><Plus size={17}/> Publish lesson</button>}</div>{lessons.length?<div className="resource-grid">{lessons.map(l=><button className="resource-card" key={l.id} onClick={()=>onOpen(l)}><div className="resource-art"><BookOpen size={28}/><span>{l.subject||'LESSON'}</span></div><div className="resource-body"><span className="eyebrow">LESSON</span><h3>{l.title}</h3><p>{l.description||'Open this lesson to view the learning material.'}</p><span className="resource-link">Open lesson <ArrowRight size={15}/></span></div></button>)}</div>:<Empty icon={<BookOpen/>} title="No lessons yet" text={isTeacher?'Publish a lesson and it will appear here.':'Your teacher’s published lessons will appear here.'} action={isTeacher?'Publish lesson':undefined} onClick={onCreate}/>}</div>
}
function Activities({activities,grades,isTeacher,onCreate,onOpen}) {
  return <div className="panel"><div className="panel-heading"><div><span className="eyebrow">PRACTICE & ASSESSMENT</span><h2>Activities and quizzes</h2><p>{isTeacher?'Create short activities to check learning.':'Practice, submit your answers, and review your results.'}</p></div>{isTeacher&&<button className="primary-btn" onClick={onCreate}><Plus size={17}/> Create activity</button>}</div>{activities.length?<div className="activity-list">{activities.map(a=>{const grade=grades.find(g=>g.activity_id===a.id);return <div className="activity-row" key={a.id}><div className="activity-icon"><ClipboardList size={20}/></div><div className="activity-main"><strong>{a.title}</strong><small>{a.subject} · {a.points} points</small></div>{grade?<span className="tag green-tag">Submitted · {grade.score}/{grade.max_score}</span>:<span className="tag yellow-tag">{isTeacher?'Published':'Not submitted'}</span>}{!isTeacher&&<button className="subtle-btn" onClick={()=>onOpen(a)}>Open <ArrowRight size={14}/></button>}</div>})}</div>:<Empty icon={<ClipboardList/>} title="Nothing to practice yet" text={isTeacher?'Create your first activity.':'New activities from your teacher will show up here.'} action={isTeacher?'Create activity':undefined} onClick={onCreate}/>}</div>
}
function Pulse({grades,average,mastered,developing,needsSupport,isTeacher,classes}) {
  return <><div className="pulse-hero panel"><div className="pulse-hero-copy"><span className="eyebrow"><Activity size={14}/> THE LEARNING PULSE</span><h2>{isTeacher?'Understand your class. Guide the next step.':'Every result is a step forward.'}</h2><p>{isTeacher?'Use saved assessment results to identify where students may need extra practice.':'Your progress is about what you understand and what you can practice next.'}</p><div className="pulse-large-number">{grades.length?`${average}%`:'—'}<small>{grades.length?'average of recorded results':'No results recorded yet'}</small></div></div><div className="pulse-hero-art"><div className="pulse-orb"><Activity size={56}/></div><div className="orb-tag top">Understand</div><div className="orb-tag bottom">Improve</div></div></div><div className="stat-grid pulse-stats"><Stat icon={<CheckCircle2/>} label="Mastered" value={mastered} tone="mint" foot="Average score 85% or higher"/><Stat icon={<Target/>} label="Developing" value={developing} tone="peach" foot="Average score 60–84%"/><Stat icon={<CircleHelp/>} label="Needs support" value={needsSupport} tone="purple" foot="Average score below 60%"/><Stat icon={<ClipboardList/>} label="Recorded results" value={grades.length} tone="blue" foot="Saved quiz and activity scores"/></div><div className="panel"><div className="panel-heading"><div><span className="eyebrow">BASED ON SAVED DATA</span><h2>{isTeacher?'Learning gap overview':'Your recent results'}</h2></div></div>{grades.length?<div className="gap-list">{grades.map(g=>{const pct=g.max_score?Math.round(g.score/g.max_score*100):0;const status=pct>=85?'Mastered':pct>=60?'Developing':'Needs Support';return <div className="gap-row" key={g.id}><div className="gap-title"><strong>{g.title}</strong><small>{g.subject||'Assessment'}</small></div><div className="gap-bar"><div className={`gap-fill ${statusMeta[status].color}`} style={{width:`${pct}%`}}/></div><strong className="gap-percent">{pct}%</strong><span className={`tag ${statusMeta[status].color}-tag`}>{statusMeta[status].dot} {status}</span></div>})}</div>:<Empty icon={<Activity/>} title="Your Learning Pulse is getting ready" text="Once assessments are submitted and saved, progress will appear here."/>}</div></>
}
function Grades({grades,average}) {
  return <div className="panel"><div className="panel-heading"><div><span className="eyebrow">YOUR RESULTS</span><h2>Grades and feedback</h2><p>Scores shown here come from saved quiz attempts.</p></div><div className="grade-average"><small>Current average</small><strong>{grades.length?`${average}%`:'—'}</strong></div></div>{grades.length?<div className="table-wrap"><table><thead><tr><th>Assessment</th><th>Subject</th><th>Score</th><th>Progress</th><th>Date</th></tr></thead><tbody>{grades.map(g=><tr key={g.id}><td><strong>{g.title}</strong></td><td>{g.subject||'—'}</td><td>{g.score}/{g.max_score}</td><td><span className={`tag ${(g.score/g.max_score)>=.85?'green-tag':(g.score/g.max_score)>=.6?'yellow-tag':'red-tag'}`}>{Math.round(g.score/g.max_score*100)}%</span></td><td>{new Date(g.created_at).toLocaleDateString()}</td></tr>)}</tbody></table></div>:<Empty icon={<ChartNoAxesCombined/>} title="No grades recorded yet" text="Completed and graded assessments will appear here."/>}</div>
}
function ParentChild({childrenList,onLink}) {
  return <div className="panel"><div className="panel-heading"><div><span className="eyebrow">FAMILY CONNECTION</span><h2>My child</h2><p>Only verified linked children are shown here.</p></div><button className="primary-btn" onClick={onLink}><Plus size={17}/> Link a child</button></div>{childrenList.length?childrenList.map(c=><div className="child-detail" key={c.id}><div className="avatar large-avatar">{initials(c.full_name)}</div><div className="child-detail-info"><h3>{c.full_name}</h3><p>Student ID: {c.student_id||'—'}</p><div className="child-stats"><div><small>Learning records</small><strong>Available in Grades and Learning Pulse</strong></div></div></div><span className="tag green-tag">Verified link</span></div>):<Empty icon={<HeartHandshake/>} title="No child linked yet" text="Enter your child's Student ID and a secure link code provided by the school." action="Link a child" onClick={onLink}/>}</div>
}
function Announcements({announcements,isTeacher,onCreate}) {
  return <div className="panel"><div className="panel-heading"><div><span className="eyebrow">CLASS UPDATES</span><h2>Announcements</h2><p>Important information from your learning community.</p></div>{isTeacher&&<button className="primary-btn" onClick={onCreate}><Plus size={17}/> New announcement</button>}</div>{announcements.length?announcements.map(a=><div className="announcement-card" key={a.id}><div className="announcement-icon"><Bell size={19}/></div><div><h3>{a.title}</h3><p>{a.body}</p><small>{new Date(a.created_at).toLocaleString()}</small></div></div>):<Empty icon={<Bell/>} title="It's quiet for now" text="New class announcements will appear here." action={isTeacher?'Post announcement':undefined} onClick={onCreate}/>}</div>
}
function Messages({messages,profile,form,setForm,onSend}) {
  return <div className="messages-layout"><div className="panel"><div className="panel-heading"><div><span className="eyebrow">STAY CONNECTED</span><h2>Message center</h2><p>Keep conversations professional and focused on learning.</p></div><MessageCircle size={20}/></div><div className="message-empty"><div className="empty-icon"><MessageCircle/></div><strong>Send a message</strong><p>To message a permitted user, enter their user ID below. Your recipient must be authorized to communicate with you.</p></div></div><div className="panel"><h2>New message</h2><form className="form-stack" onSubmit={onSend}><Field label="Recipient user ID" value={form.recipient} onChange={v=>setForm(old=>({...old,recipient:v}))} placeholder="Paste authorized recipient's user ID" required/><TextField label="Message" value={form.body} onChange={v=>setForm(old=>({...old,body:v}))} placeholder="Write your message…" required/><button className="primary-btn full"><MessageCircle size={17}/> Send message</button><p className="form-hint">This starter screen sends a saved message. Conversation history and user search can be expanded in the next development stage.</p></form></div></div>
}
function Modal({title,onClose,children}) {
  useEffect(()=>{function key(e){if(e.key==='Escape')onClose()}window.addEventListener('keydown',key);return()=>window.removeEventListener('keydown',key)},[onClose])
  return <div className="modal-backdrop" onMouseDown={e=>{if(e.target===e.currentTarget)onClose()}}><section className="modal"><header className="modal-header"><div><span className="eyebrow">EDUHUB 2.0</span><h2>{title}</h2></div><button className="icon-btn" onClick={onClose}><X size={19}/></button></header><div className="modal-content">{children}</div></section></div>
}
