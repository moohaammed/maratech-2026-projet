import { useEffect, useRef, useState } from 'react';
import { GroupChatService } from '../core/services/GroupChatService';
import './GroupChat.css';

export default function GroupChat({ user, groupId }) {
  const [msgs, setMsgs] = useState([]);
  const [text, setText] = useState('');
  const bottomRef = useRef(null);

  // real-time listener
  useEffect(() => {
    if (!groupId) return;
    const unsub = GroupChatService.subscribe(groupId, (m) => {
      setMsgs(m);
      // scroll to bottom on new message
      setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100);
    });
    return unsub;
  }, [groupId]);

  const send = async (e) => {
    e.preventDefault();
    if (!text.trim() || !user) return;
    await GroupChatService.sendMessage(
      groupId,
      user.uid,
      user.displayName || user.email?.split('@')[0],
      text
    );
    setText('');
  };

  return (
    <div className="group-chat">
      <div className="chat-header">Messagerie du groupe</div>

      <div className="chat-body">
        {msgs.length === 0 && <div className="chat-empty">Aucun message pour l’instant</div>}
        {msgs.map((m) => (
          <div
            key={m.id}
            className={`chat-bubble ${m.senderId === user.uid ? 'own' : ''}`}
          >
            <div className="chat-name">{m.senderName}</div>
            <div className="chat-text">{m.text}</div>
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      <form className="chat-footer" onSubmit={send}>
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Tapez votre message…"
          maxLength={500}
        />
        <button type="submit">Envoyer</button>
      </form>
    </div>
  );
}