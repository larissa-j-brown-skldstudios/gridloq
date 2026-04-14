// import type { Metadata } from 'next';
// import Link from 'next/link';
// import { Suspense } from 'react';
// import ErrorBoundary from '@/app/components/ErrorBoundary';
// import Loading from './loading';
// import { headers } from 'next/headers';
// import React from 'react';
// import * as Tooltip from '@radix-ui/react-tooltip';

// interface GameLayoutProps {
//   children: React.ReactNode;
//   params: {
//     id: string;
//   };
// }

// // Generate metadata for the game page
// export async function generateMetadata({ params }: GameLayoutProps): Promise<Metadata> {
//   const gameId = params.id;
  
//   return {
//     title: `Game ${gameId} - gridloq`,
//     description: `Active game session ${gameId} in gridloq - Strategic Tic-tac-toe with Power-ups`,
//     openGraph: {
//       title: `gridloq Game ${gameId}`,
//       description: 'Join this strategic Tic-tac-toe game with power-ups and special moves!',
//       type: 'website',
//       siteName: 'gridloq',
//     },
//     robots: {
//       index: false, // Don't index individual game pages
//       follow: true,
//     },
//   };
// }

// export default async function GameLayout({ children, params }: GameLayoutProps) {
//   const headersList = await headers();
//   const userAgent = headersList.get('user-agent');
//   const isMobile = userAgent?.toLowerCase().includes('mobile');
//   const { id } = params;

//   return (
//     <Tooltip.Provider delayDuration={100} skipDelayDuration={200}>
//       {/* Animated 3D Grid Background */}
//       <div
//         aria-hidden="true"
//         className="fixed inset-0 z-0 pointer-events-none"
//         style={{
//           background: "linear-gradient(180deg, #1a1333 0%, #2d1a47 100%)",
//           overflow: "hidden",
//         }}
//       >
//         <svg
//           width="100%"
//           height="100%"
//           viewBox="0 0 1920 1080"
//           preserveAspectRatio="none"
//           className="absolute inset-0 w-full h-full animate-grid-move"
//           style={{ opacity: 0.5 }}
//         >
//           {/* Horizontal grid lines */}
//           {[...Array(16)].map((_, i) => (
//             <line
//               key={`h-${i}`}
//               x1="0"
//               y1={200 + i * 50}
//               x2="1920"
//               y2={200 + i * 50}
//               stroke="#fff"
//               strokeOpacity="0.4"
//               strokeWidth="2"
//             />
//           ))}
//           {/* Perspective vertical grid lines */}
//           {[...Array(21)].map((_, i) => {
//             const x = 320 + i * 64;
//             return (
//               <polyline
//                 key={`v-${i}`}
//                 points={`960,0 ${x},1080`}
//                 fill="none"
//                 stroke="#fff"
//                 strokeOpacity="0.5"
//                 strokeWidth="2"
//               />
//             );
//           })}
//           {[...Array(21)].map((_, i) => {
//             const x = 1600 - i * 64;
//             return (
//               <polyline
//                 key={`v2-${i}`}
//                 points={`960,0 ${x},1080`}
//                 fill="none"
//                 stroke="#fff"
//                 strokeOpacity="0.5"
//                 strokeWidth="2"
//               />
//             );
//           })}
//         </svg>
//       </div>
//       <div 
//         className="container mx-auto py-6 px-4 bg-transparent" 
//         data-testid="game-layout"
//         data-game-id={id}
//       >
//         {/* Navigation */}
//         <nav className="mb-6 flex items-center justify-between">
//           <Link 
//             href="/"
//             className="inline-flex items-center text-blue-600 hover:text-blue-800 transition-colors"
//             data-testid="back-to-home"
//           >
//             <svg 
//               className="w-4 h-4 mr-2" 
//               fill="none" 
//               stroke="currentColor" 
//               viewBox="0 0 24 24"
//             >
//               <path 
//                 strokeLinecap="round" 
//                 strokeLinejoin="round" 
//                 strokeWidth={2} 
//                 d="M10 19l-7-7m0 0l7-7m-7 7h18"
//               />
//             </svg>
//             Back to Home
//           </Link>
          
//           <div className="text-sm text-gray-600">
//             Game ID: {id}
//           </div>
//         </nav>

//         {/* Main Content */}
//         <div 
//           data-testid="game-content" 
//           className={`flex-1 p-4 rounded-lg shadow-sm bg-transparent
//             ${isMobile ? 'max-w-full' : 'max-w-7xl mx-auto'}`}
//         >
//           <ErrorBoundary 
//             fallback={
//               <div className="text-center py-8">
//                 <h2 className="text-xl font-semibold text-red-600 mb-2">
//                   Something went wrong
//                 </h2>
//                 <p className="text-gray-600 mb-4">
//                   We encountered an error loading the game.
//                 </p>
//                 <Link 
//                   href="/"
//                   className="inline-block px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
//                 >
//                   Return Home
//                 </Link>
//               </div>
//             }
//           >
//             <Suspense 
//               fallback={
//                 <Loading gameId={id} />
//               }
//             >
//               {children}
//             </Suspense>
//           </ErrorBoundary>
//         </div>
//       </div>
//     </Tooltip.Provider>
//   );
// } 