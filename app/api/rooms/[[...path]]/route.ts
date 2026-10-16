import {env} from 'cloudflare:workers';
import {handleRooms} from '../../../../net/rooms.mjs';
export const dynamic='force-dynamic';
export function GET(r:Request){return handleRooms(r,env.DB)}
export function POST(r:Request){return handleRooms(r,env.DB)}
export function DELETE(r:Request){return handleRooms(r,env.DB)}
